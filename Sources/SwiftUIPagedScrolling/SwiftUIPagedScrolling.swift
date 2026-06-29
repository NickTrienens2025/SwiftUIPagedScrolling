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
    @State private var animatedIndex: CGFloat = 0
    @State private var dragDirection: DragDirection? = nil
    @State private var isDragging: Bool = false
    @State private var gestureStartIndex: Int = 0
    @State private var initialDragTranslation: CGFloat? = nil
    @GestureState private var isGestureActive: Bool = false

    @StateObject private var pagerContext = PagerContext()

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

            let onChange: (CGSize) -> Void = { translation in
                if pagerContext.isChildHandlingDrag { return }

                if !isDragging {
                    isDragging = true
                    gestureStartIndex = currentIndex
                    animatedIndex = CGFloat(currentIndex)
                }

                if dragDirection == nil {
                    let dx = abs(translation.width)
                    let dy = abs(translation.height)
                    if dx > dy * 1.2 {
                        dragDirection = .horizontal
                    } else if dy > dx * 1.2 {
                        dragDirection = .vertical
                    }
                }

                let isMatchingDirection = (orientation == .horizontal && dragDirection == .horizontal) ||
                    (orientation == .vertical && dragDirection == .vertical)

                if isMatchingDirection {
                    let currentTranslation = isHorizontal ? translation.width : translation.height

                    if initialDragTranslation == nil {
                        initialDragTranslation = currentTranslation
                    }

                    var nextOffset = currentTranslation - (initialDragTranslation ?? 0)

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

            let onEnd: (CGSize, CGSize) -> Void = { _, velocity in
                if pagerContext.isChildHandlingDrag { return }

                let isMatchingDirection = (orientation == .horizontal && dragDirection == .horizontal) ||
                    (orientation == .vertical && dragDirection == .vertical)

                guard isMatchingDirection else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        animatedIndex = CGFloat(gestureStartIndex)
                        isDragging = false
                        dragDirection = nil
                        initialDragTranslation = nil
                        offset = 0
                    }
                    return
                }

                let threshold = dimension * 0.2
                let directionalVelocity = isHorizontal ? velocity.width : velocity.height

                var newIndex = gestureStartIndex

                if offset > threshold || directionalVelocity > 400 {
                    newIndex -= 1
                } else if offset < -threshold || directionalVelocity < -400 {
                    newIndex += 1
                }

                newIndex = max(0, min(newIndex, data.count - 1))

                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentIndex = newIndex
                    animatedIndex = CGFloat(newIndex)
                    isDragging = false
                    offset = 0
                }
                dragDirection = nil
                initialDragTranslation = nil
            }

            let legacyGesture = DragGesture(minimumDistance: 15, coordinateSpace: .local)
                .updating($isGestureActive) { _, state, _ in
                    state = true
                }
                .onChanged { value in
                    onChange(value.translation)
                }
                .onEnded { value in
                    #if os(macOS)
                    onEnd(value.translation, .zero)
                    #else
                    onEnd(value.translation, value.velocity)
                    #endif
                }

            let stack = ZStack(alignment: isHorizontal ? .leading : .top) {
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
                            .environment(\.pagerContext, pagerContext)
                    }
                }
            }
            .offset(
                x: isHorizontal ? -animatedIndex * totalDimension + offset : 0,
                y: isHorizontal ? 0 : -animatedIndex * totalDimension + offset
            )

            #if os(iOS)
            if #available(iOS 18.0, *) {
                let onCancel: () -> Void = {
                    guard isDragging else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentIndex = gestureStartIndex
                        animatedIndex = CGFloat(gestureStartIndex)
                        isDragging = false
                        offset = 0
                    }
                    dragDirection = nil
                    initialDragTranslation = nil
                }

                stack.gesture(
                    PagerPanGesture(
                        axis: orientation,
                        pagerContext: pagerContext,
                        onChange: onChange,
                        onEnd: onEnd,
                        onCancel: onCancel
                    )
                )
            } else {
                stack.applyPagerGesture(gesture: legacyGesture, priority: gesturePriority)
            }
            #else
            stack.applyPagerGesture(gesture: legacyGesture, priority: gesturePriority)
            #endif
        }
        .clipped()
        .accessibilityScrollAction { edge in
            let isHorizontal = orientation == .horizontal
            if isHorizontal {
                if edge == .leading && currentIndex > 0 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentIndex -= 1
                    }
                } else if edge == .trailing && currentIndex < data.count - 1 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentIndex += 1
                    }
                }
            } else {
                if edge == .top && currentIndex > 0 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentIndex -= 1
                    }
                } else if edge == .bottom && currentIndex < data.count - 1 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        currentIndex += 1
                    }
                }
            }
        }
        .onAppear {
            animatedIndex = CGFloat(currentIndex)
        }
        .onChange(of: currentIndex) { newValue in
            if !isDragging && animatedIndex != CGFloat(newValue) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    animatedIndex = CGFloat(newValue)
                }
            }
        }
        .onChange(of: isGestureActive) { isActive in
            if !isActive && isDragging {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentIndex = gestureStartIndex
                    animatedIndex = CGFloat(gestureStartIndex)
                    isDragging = false
                    offset = 0
                }
                dragDirection = nil
                initialDragTranslation = nil
            }
        }
        .onChange(of: isDragging) { newValue in
            pagerContext.isDragging = newValue
        }
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
