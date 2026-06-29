#if os(iOS)
import SwiftUI
import UIKit

@available(iOS 18.0, *)
struct PagerPanGesture: UIGestureRecognizerRepresentable {
    let axis: Axis
    let pagerContext: PagerContext
    let onChange: (CGSize) -> Void
    let onEnd: (CGSize, CGSize) -> Void
    let onCancel: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(pagerContext: pagerContext)
    }

    func makeUIGestureRecognizer(context: Context) -> DirectionalPanGestureRecognizer {
        let recognizer = DirectionalPanGestureRecognizer()
        recognizer.axis = axis
        recognizer.cancelsTouchesInView = true
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: DirectionalPanGestureRecognizer, context: Context) {
        recognizer.axis = axis
    }

    func handleUIGestureRecognizerAction(_ recognizer: DirectionalPanGestureRecognizer, context: Context) {
        let translationPoint = recognizer.translation(in: recognizer.view)
        let velocityPoint = recognizer.velocity(in: recognizer.view)
        let translation = CGSize(width: translationPoint.x, height: translationPoint.y)
        let velocity = CGSize(width: velocityPoint.x, height: velocityPoint.y)

        switch recognizer.state {
        case .began, .changed:
            onChange(translation)
        case .ended:
            onEnd(translation, velocity)
        case .cancelled, .failed:
            onCancel()
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let pagerContext: PagerContext

        init(pagerContext: PagerContext) {
            self.pagerContext = pagerContext
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if pagerContext.isChildHandlingDrag { return false }
            guard let pan = gestureRecognizer as? DirectionalPanGestureRecognizer else { return true }

            let velocity = pan.velocity(in: pan.view)
            let movingHorizontally = abs(velocity.x) > abs(velocity.y)
            return movingHorizontally == (pan.axis == .horizontal)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            otherGestureRecognizer is UIPanGestureRecognizer
        }
    }
}

final class DirectionalPanGestureRecognizer: UIPanGestureRecognizer {
    var axis: Axis = .horizontal
}
#endif
