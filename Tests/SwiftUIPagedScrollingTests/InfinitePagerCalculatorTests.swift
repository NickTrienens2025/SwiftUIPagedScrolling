@testable import SwiftUIPagedScrolling
import XCTest

final class InfinitePagerCalculatorTests: XCTestCase {
    func testActualIndex_positiveVirtual() {
        let calc = InfinitePagerCalculator(multiplier: 10, itemsCount: 5)
        XCTAssertEqual(calc.actualIndex(for: 0), 0)
        XCTAssertEqual(calc.actualIndex(for: 1), 1)
        XCTAssertEqual(calc.actualIndex(for: 4), 4)
        XCTAssertEqual(calc.actualIndex(for: 5), 0)
        XCTAssertEqual(calc.actualIndex(for: 12), 2)
    }

    func testActualIndex_negativeVirtual() {
        let calc = InfinitePagerCalculator(multiplier: 10, itemsCount: 5)
        XCTAssertEqual(calc.actualIndex(for: -1), 4)
        XCTAssertEqual(calc.actualIndex(for: -5), 0)
        XCTAssertEqual(calc.actualIndex(for: -6), 4)
    }

    func testActualIndex_zeroItems() {
        let calc = InfinitePagerCalculator(multiplier: 10, itemsCount: 0)
        XCTAssertEqual(calc.actualIndex(for: 10), 0)
    }

    func testInitialVirtualId() {
        let calc = InfinitePagerCalculator(multiplier: 1000, itemsCount: 3)
        // Middle is at (1000 / 2) * 3 = 1500
        XCTAssertEqual(calc.initialVirtualId(for: 0), 1500)
        XCTAssertEqual(calc.initialVirtualId(for: 1), 1501)
        XCTAssertEqual(calc.initialVirtualId(for: 2), 1502)
    }

    func testJumpVirtualId_forward() {
        let calc = InfinitePagerCalculator(multiplier: 1000, itemsCount: 5)
        // Current actual: 2 (virtual 1502)
        // Target actual: 4
        // Jump diff: 2
        XCTAssertEqual(calc.jumpVirtualId(from: 1502, to: 4), 1504)
        XCTAssertEqual(calc.actualIndex(for: 1504), 4)
    }

    func testJumpVirtualId_backward() {
        let calc = InfinitePagerCalculator(multiplier: 1000, itemsCount: 5)
        // Current actual: 4 (virtual 1504)
        // Target actual: 1
        // Jump diff: -3
        XCTAssertEqual(calc.jumpVirtualId(from: 1504, to: 1), 1501)
        XCTAssertEqual(calc.actualIndex(for: 1501), 1)
    }

    func testJumpVirtualId_same() {
        let calc = InfinitePagerCalculator(multiplier: 1000, itemsCount: 5)
        XCTAssertEqual(calc.jumpVirtualId(from: 1502, to: 2), 1502)
    }
}
