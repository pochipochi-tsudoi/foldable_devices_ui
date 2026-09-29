import UIKit
import CoreGraphics

enum FoldableHingeStatus {
    case closed
    case partiallyOpen
    case fullyOpen
    case unknown
}

struct HingeReading {
    let status: FoldableHingeStatus
    let angleDegrees: Double
    let angleUnitVerified: Bool

    static let none = HingeReading(
        status: .unknown,
        angleDegrees: 0.0,
        angleUnitVerified: false
    )
}

protocol HingeSource: AnyObject {
    static var isAvailable: Bool { get }
    var currentReading: HingeReading? { get }
    var hasHinge: Bool? { get }
    var strategy: String { get }

    @discardableResult
    func start(
        on view: UIView,
        onChange: @escaping (HingeReading) -> Void
    ) -> Bool

    func stop()
}

#if FOLDABLE_NATIVE_API

@available(iOS 27.1, *)
final class DuoHingeSource: HingeSource {

    private var interaction: UIHingeInteraction?

    private(set) var currentReading: HingeReading?

    private(set) var hasHinge: Bool?

    var strategy: String {
        "UIHingeInteraction"
    }

    static var isAvailable: Bool {
        true
    }

    @discardableResult
    func start(
        on view: UIView,
        onChange: @escaping (HingeReading) -> Void
    ) -> Bool {

        // 二重登録を防ぐ
        stop()

        let interaction = UIHingeInteraction { [weak self] _, update in

            guard let self else {
                return
            }

            // hinge == nil の場合はヒンジ情報が取得できない
            guard let hinge = update.hinge else {
                self.hasHinge = false
                self.currentReading = HingeReading.none
                return
            }

            self.hasHinge = true

            // Apple API は radians なので degrees に変換
            let angleDegrees =
                Double(hinge.angle) * 180.0 / .pi

            let status: FoldableHingeStatus

            switch hinge.status {
            case .closed:
                status = .closed

            case .partiallyOpen:
                status = .partiallyOpen

            case .fullyOpen:
                status = .fullyOpen

            case .unknown:
                status = .unknown

            @unknown default:
                status = .unknown
            }

            let reading = HingeReading(
                status: status,
                angleDegrees: angleDegrees,
                angleUnitVerified: true
            )

            self.currentReading = reading

            // Flutter / 呼び出し側へ通知
            onChange(reading)
        }

        view.addInteraction(interaction)

        self.interaction = interaction

        return true
    }

    func stop() {
        guard let interaction else {
            return
        }

        interaction.view?.removeInteraction(interaction)

        self.interaction = nil
    }
}

#endif
