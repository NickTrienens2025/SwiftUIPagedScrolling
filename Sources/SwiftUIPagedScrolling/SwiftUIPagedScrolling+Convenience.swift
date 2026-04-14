import SwiftUI

public extension SwiftUIPagedScrolling where Data.Element: Identifiable, ID == Data.Element.ID {
    init(
        data: Data,
        currentIndex: Binding<Int>,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.init(data: data, id: \.id, currentIndex: currentIndex, content: content)
    }
}

public extension SwiftUIPagedScrolling where Data == Range<Int>, ID == Int {
    /// Simplified interface for numeric sequences, replacing `data: Array(0..<count)` boilerplate.
    init(
        pageCount: Int,
        currentIndex: Binding<Int>,
        @ViewBuilder content: @escaping (Int) -> Content
    ) {
        self.init(data: 0 ..< pageCount, id: \.self, currentIndex: currentIndex, content: content)
    }
}

public extension SwiftUIPagedScrolling where ID == Data.Element, Data.Element: Hashable {
    /// Simplified interface for standard hashable data collections, omitting explicit keypaths.
    init(
        _ data: Data,
        currentIndex: Binding<Int>,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.init(data: data, id: \.self, currentIndex: currentIndex, content: content)
    }
}
