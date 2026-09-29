import Foundation
import ObjectiveC
import UIKit

/// Objective-C runtime helpers used to reach APIs that are not in the SDK this
/// package is compiled against.
///
/// The iPhone Duo hinge APIs ship in the iOS 27.1 SDK, but this package must
/// keep compiling with older toolchains. No iOS 27 type is ever named in Swift
/// source here, only looked up as a string at runtime, so the compiler never
/// sees an unknown symbol.
enum ObjCRuntimeSupport {
  /// Whether `cls` conforms to the Objective-C protocol named `name`.
  static func conforms(_ cls: AnyClass, toProtocolNamed name: String) -> Bool {
    guard let proto = objc_getProtocol(name) else { return false }
    return class_conformsToProtocol(cls, proto)
  }

  /// Reads a key path safely, returning `nil` when any segment is missing.
  static func value(from object: NSObject, keyPath: String) -> Any? {
    var current: NSObject = object
    let segments = keyPath.split(separator: ".").map(String.init)

    for (index, segment) in segments.enumerated() {
      guard hasProperty(current, segment) else { return nil }
      guard let next = current.value(forKey: segment) else { return nil }
      if index == segments.count - 1 { return next }
      guard let nextObject = next as? NSObject else { return nil }
      current = nextObject
    }
    return nil
  }

  /// Whether `object` exposes `key` as a declared property or selector.
  private static func hasProperty(_ object: NSObject, _ key: String) -> Bool {
    let cls: AnyClass = type(of: object)
    if class_getProperty(cls, key) != nil { return true }
    return object.responds(to: NSSelectorFromString(key))
  }

  private typealias AllocIMP = @convention(c) (AnyClass, Selector) -> Unmanaged<AnyObject>?
  private typealias InitWithObjectIMP = @convention(c) (AnyObject, Selector, AnyObject) -> Unmanaged<AnyObject>?

  /// Allocates and initialises an object whose designated initialiser takes
  /// one object argument, such as `-[UIHingeInteraction initWithUpdateHandler:]`.
  static func makeObject(
    className: String, initSelector selectorName: String, argument: AnyObject
  ) -> NSObject? {
    guard let cls = NSClassFromString(className) else { return nil }
    let initSelector = NSSelectorFromString(selectorName)
    guard cls.instancesRespond(to: initSelector) else { return nil }

    guard let metaclass = object_getClass(cls),
          let allocIMP = class_getMethodImplementation(metaclass, NSSelectorFromString("alloc"))
    else { return nil }
    let alloc = unsafeBitCast(allocIMP, to: AllocIMP.self)
    guard let raw = alloc(cls, NSSelectorFromString("alloc"))?.takeUnretainedValue()
    else { return nil }

    guard let initIMP = class_getMethodImplementation(cls, initSelector)
    else { return nil }
    let initialise = unsafeBitCast(initIMP, to: InitWithObjectIMP.self)
    return initialise(raw, initSelector, argument)?.takeRetainedValue() as? NSObject
  }
}
