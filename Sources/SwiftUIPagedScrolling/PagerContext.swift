import SwiftUI

public class PagerContext: ObservableObject {
    public var isChildHandlingDrag: Bool = false
    public init() {}
}

struct PagerContextKey: EnvironmentKey {
    static let defaultValue: PagerContext? = nil
}

public extension EnvironmentValues {
    var pagerContext: PagerContext? {
        get { self[PagerContextKey.self] }
        set { self[PagerContextKey.self] = newValue }
    }
}

public extension View {
    /// Applies a modifier that intercepts touches immediately, signaling the parent
    /// `SwiftUIPagedScrolling` view to ignore its own DragGesture. This allows nested
    /// ScrollViews on the same axis as the Pager to function perfectly while the Pager
    /// remains in `.simultaneous` priority for orthogonal locking.
    func ignorePagerGesture() -> some View {
        self.modifier(IgnorePagerGestureModifier())
    }
}

private struct IgnorePagerGestureModifier: ViewModifier {
    @Environment(\.pagerContext) var pagerContext
    @State private var isTouching = false

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isTouching {
                            isTouching = true
                            pagerContext?.isChildHandlingDrag = true
                        }
                    }
                    .onEnded { _ in
                        if isTouching {
                            isTouching = false
                            pagerContext?.isChildHandlingDrag = false
                        }
                    }
            )
    }
}
