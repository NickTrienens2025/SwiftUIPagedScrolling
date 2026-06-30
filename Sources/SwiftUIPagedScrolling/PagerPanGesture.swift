#if os(iOS)
import SwiftUI
import UIKit

final class DirectionalPanGestureRecognizer: UIPanGestureRecognizer {
    var axis: Axis = .horizontal
}

func dispatchPagerPan(
    _ recognizer: DirectionalPanGestureRecognizer,
    onChange: (CGSize) -> Void,
    onEnd: (CGSize, CGSize) -> Void,
    onCancel: () -> Void
) {
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

class PagerPanDelegate: NSObject, UIGestureRecognizerDelegate {
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

@available(iOS 18.0, *)
struct PagerPanGesture: UIGestureRecognizerRepresentable {
    let axis: Axis
    let pagerContext: PagerContext
    let onChange: (CGSize) -> Void
    let onEnd: (CGSize, CGSize) -> Void
    let onCancel: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> PagerPanDelegate {
        PagerPanDelegate(pagerContext: pagerContext)
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
        dispatchPagerPan(recognizer, onChange: onChange, onEnd: onEnd, onCancel: onCancel)
    }
}

struct PagerPanInjector: UIViewRepresentable {
    let axis: Axis
    let pagerContext: PagerContext
    let onChange: (CGSize) -> Void
    let onEnd: (CGSize, CGSize) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(pagerContext: pagerContext, onChange: onChange, onEnd: onEnd, onCancel: onCancel)
    }

    func makeUIView(context: Context) -> PagerPanHostView {
        let view = PagerPanHostView()
        view.isUserInteractionEnabled = false

        let recognizer = DirectionalPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        recognizer.axis = axis
        recognizer.cancelsTouchesInView = true
        recognizer.delegate = context.coordinator

        context.coordinator.recognizer = recognizer
        view.recognizer = recognizer
        return view
    }

    func updateUIView(_ uiView: PagerPanHostView, context: Context) {
        context.coordinator.update(onChange: onChange, onEnd: onEnd, onCancel: onCancel)
        uiView.recognizer?.axis = axis
    }

    final class Coordinator: PagerPanDelegate {
        private var onChange: (CGSize) -> Void
        private var onEnd: (CGSize, CGSize) -> Void
        private var onCancel: () -> Void
        weak var recognizer: DirectionalPanGestureRecognizer?

        init(
            pagerContext: PagerContext,
            onChange: @escaping (CGSize) -> Void,
            onEnd: @escaping (CGSize, CGSize) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onChange = onChange
            self.onEnd = onEnd
            self.onCancel = onCancel
            super.init(pagerContext: pagerContext)
        }

        func update(
            onChange: @escaping (CGSize) -> Void,
            onEnd: @escaping (CGSize, CGSize) -> Void,
            onCancel: @escaping () -> Void
        ) {
            self.onChange = onChange
            self.onEnd = onEnd
            self.onCancel = onCancel
        }

        @objc func handlePan(_ recognizer: DirectionalPanGestureRecognizer) {
            dispatchPagerPan(recognizer, onChange: onChange, onEnd: onEnd, onCancel: onCancel)
        }
    }
}

final class PagerPanHostView: UIView {
    var recognizer: DirectionalPanGestureRecognizer?
    private weak var attachedView: UIView?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, let recognizer, attachedView == nil, let target = hostTargetView() else { return }
        target.addGestureRecognizer(recognizer)
        attachedView = target
    }

    private func hostTargetView() -> UIView? {
        var responder: UIResponder? = next
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController.view
            }
            responder = current.next
        }
        return superview
    }
}
#endif
