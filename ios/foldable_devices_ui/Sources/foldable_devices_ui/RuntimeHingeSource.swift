import Foundation
import ObjectiveC
import UIKit

/// Reads the hinge through the Objective-C runtime.
///
/// The real API, confirmed against the iOS 27.1 SDK headers:
///
/// ```objc
/// @interface UIHingeInteraction : NSObject <UIInteraction>
/// - (instancetype)initWithUpdateHandler:
///     (void(^)(UIHingeInteraction *, UIHingeInteractionUpdate *))updateHandler
///     NS_DESIGNATED_INITIALIZER;
/// @end
///
/// @interface UIHingeInteractionUpdate : NSObject
/// @property (readonly, nullable) UIHinge *hinge;
/// @end
///
/// @interface UIHinge : NSObject
/// @property (readonly) UIHingeStatus status;
/// @property (readonly) CGFloat angle;  // angle is in RADIANS
/// @end
/// ```
///
/// None of those types are named in Swift source here, so this file still
/// compiles against older SDKs. On a device without the API the class lookup
/// fails and the source reports that it could not start.
final class RuntimeHingeSource: HingeSource {
  private static let interactionClass = "UIHingeInteraction"
  private static let initSelector = "initWithUpdateHandler:"

  private var interaction: NSObject?
  private weak var attachedView: UIView?
  private var onChange: ((HingeReading) -> Void)?
  private var latest: HingeReading?
  private var knownHasHinge: Bool?

  static var isAvailable: Bool {
    guard let cls = NSClassFromString(interactionClass) else { return false }
    return cls.instancesRespond(to: NSSelectorFromString(initSelector))
  }

  var strategy: String { "runtime" }
  var currentReading: HingeReading? { latest }
  var hasHinge: Bool? { knownHasHinge }

  @discardableResult
  func start(on view: UIView, onChange: @escaping (HingeReading) -> Void) -> Bool {
    self.onChange = onChange
    if interaction != nil { return true }

    let handler: @convention(block) (AnyObject?, AnyObject?) -> Void = { [weak self] _, update in
      self?.handle(update)
    }

    guard let created = ObjCRuntimeSupport.makeObject(
      className: Self.interactionClass,
      initSelector: Self.initSelector,
      argument: handler as AnyObject
    ) else { return false }

    guard ObjCRuntimeSupport.conforms(type(of: created), toProtocolNamed: "UIInteraction")
    else { return false }

    view.addInteraction(unsafeBitCast(created, to: UIInteraction.self))
    interaction = created
    attachedView = view
    return true
  }

  func stop() {
    if let interaction = interaction, let view = attachedView,
       ObjCRuntimeSupport.conforms(type(of: interaction), toProtocolNamed: "UIInteraction") {
      view.removeInteraction(unsafeBitCast(interaction, to: UIInteraction.self))
    }
    interaction = nil
    attachedView = nil
    onChange = nil
  }

  // MARK: - Reading an update
  private func handle(_ update: AnyObject?) {
    guard let update = update as? NSObject else { return }

    guard let hinge = ObjCRuntimeSupport.value(from: update, keyPath: "hinge") as? NSObject else {
      knownHasHinge = false
      let reading = HingeReading.none
      latest = reading
      onChange?(reading)
      return
    }

    knownHasHinge = true
    let reading = HingeReading(
      status: Self.status(from: hinge),
      angleDegrees: Self.angleDegrees(from: hinge) ?? 0.0,
      angleUnitVerified: true
    )
    latest = reading
    onChange?(reading)
  }

  private static func status(from hinge: NSObject) -> FoldableHingeStatus {
    guard let raw = ObjCRuntimeSupport.value(from: hinge, keyPath: "status") as? NSNumber
    else { return .unknown }
    switch raw.intValue {
    case 1: return .closed
    case 2: return .partiallyOpen
    case 3: return .fullyOpen
    default: return .unknown
    }
  }

  private static func angleDegrees(from hinge: NSObject) -> Double? {
    guard let raw = ObjCRuntimeSupport.value(from: hinge, keyPath: "angle") as? NSNumber
    else { return nil }
    let degrees = raw.doubleValue * 180.0 / Double.pi
    return min(max(degrees, 0), 180)
  }
}
