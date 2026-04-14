import SwiftUI

public extension SwiftUIPagedScrolling {
    func pageSpacing(_ spacing: CGFloat) -> SwiftUIPagedScrolling {
        var copy = self
        copy.pageSpacing = spacing
        return copy
    }

    func preloadAmount(_ amount: Int) -> SwiftUIPagedScrolling {
        var copy = self
        copy.preloadAmount = amount
        return copy
    }

    func pageOrientation(_ orientation: Axis) -> SwiftUIPagedScrolling {
        var copy = self
        copy.orientation = orientation
        return copy
    }

    func pagerGesturePriority(_ priority: PagerGesturePriority) -> SwiftUIPagedScrolling {
        var copy = self
        copy.gesturePriority = priority
        return copy
    }
}
