import SwiftUI
@testable import SwiftUIPagedScrolling
import XCTest

final class SwiftUIPagedScrollingTests: XCTestCase {
    struct TestItem: Identifiable, Hashable {
        let id: Int
        let name: String
    }

    func testCompilation() {
        let data = [
            TestItem(id: 1, name: "One"),
            TestItem(id: 2, name: "Two"),
            TestItem(id: 3, name: "Three"),
        ]

        let binding = Binding.constant(0)

        let pager = SwiftUIPagedScrolling(data: data, currentIndex: binding) { item in
            Text(item.name)
        }
        .pageSpacing(10)
        .preloadAmount(3)

        XCTAssertNotNil(pager)
    }

    func testBodyEvaluationDoesNotCrashOnBoundaryIndices() {
        let data = [
            TestItem(id: 1, name: "One"),
            TestItem(id: 2, name: "Two"),
            TestItem(id: 3, name: "Three"),
        ]

        // Test negative out-of-bounds index doesn't crash evaluation
        let bindingLow = Binding.constant(-1)
        let pagerLow = SwiftUIPagedScrolling(data: data, currentIndex: bindingLow) { item in
            Text(item.name)
        }
        XCTAssertNotNil(pagerLow.body)

        // Test positive out-of-bounds index doesn't crash evaluation
        let bindingHigh = Binding.constant(10)
        let pagerHigh = SwiftUIPagedScrolling(data: data, currentIndex: bindingHigh) { item in
            Text(item.name)
        }
        XCTAssertNotNil(pagerHigh.body)

        // Test edge boundaries
        let bindingEdge0 = Binding.constant(0)
        let pagerEdge0 = SwiftUIPagedScrolling(data: data, currentIndex: bindingEdge0) { item in
            Text(item.name)
        }
        XCTAssertNotNil(pagerEdge0.body)

        let bindingEdgeMax = Binding.constant(data.count - 1)
        let pagerEdgeMax = SwiftUIPagedScrolling(data: data, currentIndex: bindingEdgeMax) { item in
            Text(item.name)
        }
        XCTAssertNotNil(pagerEdgeMax.body)
    }
}
