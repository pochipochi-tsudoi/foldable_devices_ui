import Flutter
import Darwin
import UIKit

public class FoldableDevicesUiPlugin: NSObject, FlutterPlugin {
  private var streamHandler: AngleStreamHandler?

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
    registrar.addMethodCallDelegate(instance, channel: deviceChannel)

    registrar.addApplicationDelegate(instance)
    instance.installInteractionWhenPossible()

    registrar.publish(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "isIphoneDuo" else {
      result(FlutterMethodNotImplemented)
      return
    }
    result(Self.isIphoneDuo)
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

  /// Attaches the hinge interaction to the Flutter view once one exists.
  /// Retried rather than done once, because at registration time the window
  /// may not have a root view yet.
  func installInteractionWhenPossible() {
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
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene,
            windowScene.activationState == .foregroundActive
              || windowScene.activationState == .foregroundInactive
      else { continue }
      let window =
        windowScene.windows.first(where: { $0.isKeyWindow })
        ?? windowScene.windows.first
      if let view = window?.rootViewController?.view ?? window {
        return view
      }
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
