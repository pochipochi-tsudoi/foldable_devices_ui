import Flutter
import Darwin
import UIKit

public class FoldableDevicesUiPlugin: NSObject, FlutterPlugin {
  private var streamHandler: AngleStreamHandler?
  private var deviceChannel: FlutterMethodChannel?
  private weak var toolbarNavigationController: UINavigationController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FoldableDevicesUiPlugin()

    let handler = AngleStreamHandler()
    instance.streamHandler = handler

    let eventChannel = FlutterEventChannel(
      name: "foldable_devices_ui/angle",
      binaryMessenger: registrar.messenger()
    )
    eventChannel.setStreamHandler(handler)

    let deviceChannel = FlutterMethodChannel(
      name: "foldable_devices_ui/device",
      binaryMessenger: registrar.messenger()
    )
    instance.deviceChannel = deviceChannel
    registrar.addMethodCallDelegate(instance, channel: deviceChannel)

    registrar.addApplicationDelegate(instance)
    instance.installInteractionWhenPossible()

    registrar.publish(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isIphoneDuo":
      let isDuo = Self.isIphoneDuo
      if isDuo {
        installToolbarNavigationControllerWhenPossible()
      }
      result(isDuo)
    case "updateToolbarActions":
      guard Self.isIphoneDuo,
            let arguments = call.arguments as? [String: Any]
      else {
        result(nil)
        return
      }
      guard let navigationController = installToolbarNavigationControllerWhenPossible() else {
        result(FlutterError(
          code: "toolbar_host_unavailable",
          message: "The iPhone Duo FlutterViewController is not attached to a window yet.",
          details: nil
        ))
        return
      }
      updateToolbarItems(arguments, on: navigationController)
      result(nil)
    case "getBarLayoutInsets":
      guard Self.isIphoneDuo,
            let window = Self.hostWindow()
      else {
        result([
          "top": 0.0,
          "bottom": 16.0,
          "hasPunchHoleAtBottom": false,
        ])
        return
      }

      let orientation: UIInterfaceOrientation
      if #available(iOS 13.0, *), let scene = window.windowScene {
        orientation = scene.interfaceOrientation
      } else {
        orientation = UIApplication.shared.statusBarOrientation
      }

      // On iPhone Duo Outer Display in landscape orientation:
      // - landscapeRight: Dynamic Island is at the top-left, so bottom has NO punch-hole (bottom: 16.0)
      // - landscapeLeft: Dynamic Island is rotated 180° to the bottom, so bottom HAS punch-hole (bottom: 112.0)
      // - portrait / portraitUpsideDown: Dynamic Island does not collide with bottom bar (bottom: 16.0)
      let hasPunchHoleAtBottom = (orientation == .landscapeLeft)
      let bottomInset: Double = hasPunchHoleAtBottom ? 112.0 : 16.0
      let topInset: Double = (orientation == .landscapeRight) ? 82.0 : 0.0

      result([
        "top": topInset,
        "bottom": bottomInset,
        "hasPunchHoleAtBottom": hasPunchHoleAtBottom,
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static var isIphoneDuo: Bool {
    #if targetEnvironment(simulator)
      if let simulatorModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
        return simulatorModel == "iPhone19,4"
      }
    #endif

    var systemInfo = utsname()
    guard uname(&systemInfo) == 0 else { return false }
    let machineCapacity = MemoryLayout.size(ofValue: systemInfo.machine)
    let machineIdentifier = withUnsafePointer(to: &systemInfo.machine) { machine in
      machine.withMemoryRebound(to: CChar.self, capacity: machineCapacity) {
        String(cString: $0)
      }
    }
    return machineIdentifier == "iPhone19,4"
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    installInteractionWhenPossible()
  }

  /// Embeds Flutter's root controller in a UIKit navigation container so iOS
  /// can place its navigation items in the iPhone Duo system bar.
  @discardableResult
  private func installToolbarNavigationControllerWhenPossible() -> UINavigationController? {
    if let existing = toolbarNavigationController {
      return existing
    }
    guard let window = Self.hostWindow(), let root = window.rootViewController else {
      scheduleHostInstallationRetry()
      return nil
    }

    if let navigationController = root as? UINavigationController,
       navigationController.viewControllers.contains(where: { $0 is FlutterViewController }) {
      toolbarNavigationController = navigationController
      return navigationController
    }

    guard let flutterViewController = root as? FlutterViewController else {
      return nil
    }

    window.rootViewController = nil
    let navigationController = UINavigationController(
      rootViewController: flutterViewController
    )
    navigationController.setNavigationBarHidden(false, animated: false)
    window.rootViewController = navigationController
    toolbarNavigationController = navigationController
    return navigationController
  }

  private func scheduleHostInstallationRetry() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
      guard let self = self, Self.hostWindow()?.rootViewController != nil else { return }
      self.installToolbarNavigationControllerWhenPossible()
    }
  }

  private func updateToolbarItems(
    _ arguments: [String: Any],
    on navigationController: UINavigationController
  ) {
    let navigationItem = navigationController.topViewController?.navigationItem
    guard let navigationItem else { return }

    let canPop = arguments["canPop"] as? Bool ?? false
    let actions = arguments["actions"] as? [[String: Any]] ?? []

    var leadingItems: [UIBarButtonItem] = []
    var actionItems: [UIBarButtonItem] = []
    var independentItems: [UIBarButtonItem] = []

    if canPop && !actions.contains(where: { ($0["role"] as? String) == "back" }) {
      let backItem = UIBarButtonItem(
        image: UIImage(systemName: "chevron.left"),
        style: .plain,
        target: self,
        action: #selector(toolbarItemTapped(_:))
      )
      backItem.accessibilityIdentifier = "duo.autoBack"
      backItem.accessibilityLabel = "Back"
      configure(backItem, priority: 100)
      leadingItems.append(backItem)
    }

    for action in actions {
      guard let id = action["id"] as? String else { continue }
      let role = action["role"] as? String ?? "action"
      if role == "destination" {
        continue
      }
      let isIndependent = action["independent"] as? Bool ?? false
      let isPrimary = action["isPrimary"] as? Bool ?? false
      let isSelected = action["selected"] as? Bool == true

      let imageBytes = (isSelected ? action["selectedIcon"] : nil) as? FlutterStandardTypedData
        ?? action["icon"] as? FlutterStandardTypedData
      let image = imageBytes.flatMap { UIImage(data: $0.data) }?.withRenderingMode(.alwaysOriginal)
      let label = action["label"] as? String
      let item: UIBarButtonItem

      if let children = action["children"] as? [[String: Any]], !children.isEmpty {
        let menuActions: [UIAction] = children.compactMap { child in
          guard let childId = child["id"] as? String else { return nil }
          let childLabel = (child["label"] as? String) ?? "Action"
          let childBytes = child["icon"] as? FlutterStandardTypedData
          let childImage = childBytes.flatMap { UIImage(data: $0.data) }?.withRenderingMode(.alwaysOriginal)
          let childEnabled = child["enabled"] as? Bool ?? true
          let uiAction = UIAction(title: childLabel, image: childImage) { [weak self] _ in
            self?.deviceChannel?.invokeMethod("toolbarActionPressed", arguments: ["id": childId])
          }
          if !childEnabled {
            uiAction.attributes = .disabled
          }
          return uiAction
        }
        let menu = UIMenu(title: "", children: menuActions)
        item = UIBarButtonItem(
          image: image ?? UIImage(systemName: "ellipsis.circle") ?? UIImage(systemName: "ellipsis"),
          menu: menu
        )
      } else if let image {
        item = UIBarButtonItem(
          image: image,
          style: .plain,
          target: self,
          action: #selector(toolbarItemTapped(_:))
        )
      } else {
        item = UIBarButtonItem(
          title: label ?? "Action",
          style: .plain,
          target: self,
          action: #selector(toolbarItemTapped(_:))
        )
      }
      item.accessibilityIdentifier = id
      item.accessibilityLabel = label
      item.isEnabled = action["enabled"] as? Bool ?? true
      if isSelected {
        item.tintColor = .tintColor
      }
      if #available(iOS 16.0, *), item.menu == nil {
        let menuAction = UIAction(title: label ?? "Action", image: image) { [weak self] _ in
          self?.deviceChannel?.invokeMethod("toolbarActionPressed", arguments: ["id": id])
        }
        if !item.isEnabled {
          menuAction.attributes = .disabled
        }
        item.menuRepresentation = menuAction
      }
      configure(item, priority: action["priority"] as? Int ?? 0)

      if role == "back" {
        leadingItems.append(item)
      } else if isIndependent || isPrimary || role == "primary" {
        independentItems.append(item)
      } else {
        actionItems.append(item)
      }
    }

    navigationItem.leftBarButtonItems = leadingItems.isEmpty ? nil : leadingItems

    // HIG: If multiple secondary actions were passed ungrouped, collapse them into a single menu item.
    let effectiveActionItems: [UIBarButtonItem]
    if actionItems.count > 1 {
      let menuElements: [UIMenuElement] = actionItems.compactMap { barItem in
        if #available(iOS 16.0, *), let rep = barItem.menuRepresentation {
          return rep
        }
        guard let itemId = barItem.accessibilityIdentifier else { return nil }
        return UIAction(title: barItem.accessibilityLabel ?? "Action", image: barItem.image) { [weak self] _ in
          self?.deviceChannel?.invokeMethod("toolbarActionPressed", arguments: ["id": itemId])
        }
      }
      let groupedItem = UIBarButtonItem(
        image: UIImage(systemName: "ellipsis.circle") ?? UIImage(systemName: "ellipsis"),
        menu: UIMenu(title: "", children: menuElements)
      )
      groupedItem.accessibilityIdentifier = "duo.groupedActions"
      groupedItem.accessibilityLabel = "More"
      configure(groupedItem, priority: 50)
      effectiveActionItems = [groupedItem]
    } else {
      effectiveActionItems = actionItems
    }

    var allTrailing: [UIBarButtonItem] = []
    allTrailing.append(contentsOf: effectiveActionItems)
    allTrailing.append(contentsOf: independentItems)

    if #available(iOS 16.0, *) {
      navigationItem.pinnedTrailingGroup = nil
      if allTrailing.isEmpty {
        navigationItem.trailingItemGroups = []
      } else {
        navigationItem.trailingItemGroups = [
          UIBarButtonItemGroup.fixedGroup(items: allTrailing)
        ]
      }
    } else {
      navigationItem.rightBarButtonItems = allTrailing.isEmpty ? nil : allTrailing
    }
  }

  private func configure(_ item: UIBarButtonItem, priority: Int) {
    if #available(iOS 27.1, *) {
      item.axisBehavior = .verticalPreferred
    }
    if #available(iOS 27.0, *) {
      switch priority {
      case 80...:
        item.visibilityPriority = .high
      case ..<40:
        item.visibilityPriority = .low
      default:
        item.visibilityPriority = .standard
      }
    }
  }

  @objc private func toolbarItemTapped(_ sender: UIBarButtonItem) {
    guard let id = sender.accessibilityIdentifier else { return }
    deviceChannel?.invokeMethod("toolbarActionPressed", arguments: ["id": id])
  }

  /// Attaches the hinge interaction to the Flutter view once one exists.
  /// Retried rather than done once, because at registration time the window
  /// may not have a root view yet.
  func installInteractionWhenPossible() {
    if Self.isIphoneDuo && installToolbarNavigationControllerWhenPossible() == nil {
      scheduleHostInstallationRetry()
    }
    guard let view = Self.hostView() else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
        guard let self = self, Self.hostView() != nil else { return }
        self.installInteractionWhenPossible()
      }
      return
    }

    streamHandler?.installHingeInteraction(on: view)
  }

  /// The view the interaction attaches to.
  static func hostView() -> UIView? {
    guard let window = hostWindow() else { return nil }
    if let navigationController = window.rootViewController as? UINavigationController,
       let flutterViewController = navigationController.viewControllers
         .first(where: { $0 is FlutterViewController }) as? FlutterViewController {
      return flutterViewController.view
    }
    return window.rootViewController?.view ?? window
  }

  private static func hostWindow() -> UIWindow? {
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene,
            windowScene.activationState == .foregroundActive
              || windowScene.activationState == .foregroundInactive
      else { continue }
      let window =
        windowScene.windows.first(where: { $0.isKeyWindow })
        ?? windowScene.windows.first
      if let window { return window }
    }
    return nil
  }
}

public class AngleStreamHandler: NSObject, FlutterStreamHandler {
  private let hingeSource: HingeSource
  private var sink: FlutterEventSink?

  override init() {
    hingeSource = RuntimeHingeSource()
    super.init()
  }

  func installHingeInteraction(on view: UIView) {
    hingeSource.start(on: view) { [weak self] reading in
      self?.emit(reading)
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events

    if RuntimeHingeSource.isAvailable {
      if let current = hingeSource.currentReading {
        events(current.angleDegrees)
      }
    } else {
      events(0.0)
    }

    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  private func emit(_ reading: HingeReading) {
    guard let sink = sink else { return }
    let value = reading.angleDegrees
    if Thread.isMainThread {
      sink(value)
    } else {
      DispatchQueue.main.async {
        sink(value)
      }
    }
  }
}
