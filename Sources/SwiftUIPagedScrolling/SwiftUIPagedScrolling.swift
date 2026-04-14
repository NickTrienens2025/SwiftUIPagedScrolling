import SwiftUI

public enum PagerGesturePriority {
    case standard
    case high
    case simultaneous
}

public struct SwiftUIPagedScrolling<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    @Binding private var currentIndex: Int
    private let content: (Data.Element) -> Content

    @State private var offset: CGFloat = 0
    @State private var dragDirection: DragDirection? = nil
    @State private var isDragging: Bool = false
    @State private var gestureStartIndex: Int = 0

    // Configuration
    var pageSpacing: CGFloat = 0
    var preloadAmount: Int = 2
    var orientation: Axis = .horizontal
    var gesturePriority: PagerGesturePriority = .simultaneous

    public enum DragDirection {
        case horizontal
        case vertical
    }

    public init(
        data: Data,
        id: KeyPath<Data.Element, ID>,
        currentIndex: Binding<Int>,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.id = id
        _currentIndex = currentIndex
        self.content = content
    }

    public var body: some View {
        GeometryReader { proxy in
            let isHorizontal = orientation == .horizontal
            let dimension = isHorizontal ? proxy.size.width : proxy.size.height
            let totalDimension = dimension + pageSpacing
            let activeIndex = isDragging ? gestureStartIndex : currentIndex
            let minIndex = max(0, activeIndex - preloadAmount)
            let maxIndex = max(minIndex, min(data.count - 1, activeIndex + preloadAmount))
            let visibleRange = minIndex ... maxIndex
            
            // Only apply robust scroll-disabling if priority is simultaneous.
            let shouldDisableScrolling = gesturePriority == .simultaneous
            let disableScrolling = shouldDisableScrolling && isDragging && ((orientation == .horizontal && dragDirection == .horizontal) || (orientation == .vertical && dragDirection == .vertical))

            ZStack(alignment: isHorizontal ? .leading : .top) {
                if !data.isEmpty {
                    ForEach(Array(visibleRange), id: \.self) { index in
                        let element = data[data.index(data.startIndex, offsetBy: index)]
                        content(element)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .offset(
                                x: isHorizontal ? CGFloat(index) * totalDimension : 0,
                                y: isHorizontal ? 0 : CGFloat(index) * totalDimension
                            )
                            .scrollDisabled(disableScrolling)
                    }
                }
            }
            .offset(
                x: isHorizontal ? -CGFloat(isDragging ? gestureStartIndex : currentIndex) * totalDimension + offset : 0,
                y: isHorizontal ? 0 : -CGFloat(isDragging ? gestureStartIndex : currentIndex) * totalDimension + offset
            )
            .applyPagerGesture(
                gesture: DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            gestureStartIndex = currentIndex
                        }

                        if dragDirection == nil {
                            let dx = abs(value.translation.width)
                            let dy = abs(value.translation.height)
                            if dx > dy * 1.2 {
                                dragDirection = .horizontal
                            } else if dy > dx * 1.2 {
                                dragDirection = .vertical
                            }
                        }

                        let isMatchingDirection = (orientation == .horizontal && dragDirection == .horizontal) ||
                            (orientation == .vertical && dragDirection == .vertical)

                        if isMatchingDirection {
                            var nextOffset = isHorizontal ? value.translation.width : value.translation.height
                            if gestureStartIndex == 0, nextOffset > 0 {
                                nextOffset = friction(nextOffset)
                            } else if gestureStartIndex == data.count - 1, nextOffset < 0 {
                                nextOffset = -friction(-nextOffset)
                            }
                            offset = nextOffset

                            let halfDimension = totalDimension / 2.0
                            var targetIndex = gestureStartIndex
                            if offset < -halfDimension {
                                targetIndex = gestureStartIndex + 1
                            } else if offset > halfDimension {
                                targetIndex = gestureStartIndex - 1
                            }

                            targetIndex = max(0, min(targetIndex, data.count - 1))

                            if currentIndex != targetIndex {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    currentIndex = targetIndex
                                }
                            }
                        }
                    }
                    .onEnded { value in
                        let isMatchingDirection = (orientation == .horizontal && dragDirection == .horizontal) ||
                            (orientation == .vertical && dragDirection == .vertical)

                        guard isMatchingDirection else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isDragging = false
                                dragDirection = nil
                                offset = 0
                            }
                            return
                        }

                        let threshold = dimension * 0.2
                        #if os(macOS)
                            let velocity: CGFloat = 0 // macOS does not provide velocity on DragGesture value
                        #else
                            let velocity = isHorizontal ? value.velocity.width : value.velocity.height
                        #endif

                        var newIndex = gestureStartIndex

                        if offset > threshold || velocity > 400 {
                            newIndex -= 1
                        } else if offset < -threshold || velocity < -400 {
                            newIndex += 1
                        }

                        newIndex = max(0, min(newIndex, data.count - 1))

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentIndex = newIndex
                            isDragging = false
                            offset = 0
                        }
                        dragDirection = nil
                    },
                priority: gesturePriority
            )
        }
        .clipped()
    }

    private func friction(_ value: CGFloat) -> CGFloat {
        return value * 0.3 // Simple friction
    }
}

private extension View {
    @ViewBuilder
    func applyPagerGesture<G: Gesture>(gesture: G, priority: PagerGesturePriority) -> some View {
        switch priority {
        case .standard:
            self.gesture(gesture)
        case .high:
            self.highPriorityGesture(gesture)
        case .simultaneous:
            self.simultaneousGesture(gesture)
        }
    }
}
