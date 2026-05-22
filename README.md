# SwiftUIPagedScrolling

A highly modular, performant, and flexible SwiftUI paging component. `SwiftUIPagedScrolling` provides a clean, native SwiftUI architecture (avoiding UIKit technical debt) for building beautiful, smooth, paged scrolling experiences.

## Features

* **Native SwiftUI:** Built entirely with SwiftUI using a modern ZStack-based architecture.
* **Multi-Axis Support:** Supports both horizontal and vertical scrolling out of the box.
* **Modular Design:** Core logic, modifiers, and view builders are cleanly separated for maintainability and extensibility.
* **Customizable:** Highly customizable item spacing, padding, alignment, and gesture properties.

## Requirements

* iOS 16.0+
* macOS 13.0+
* tvOS 16.0+
* watchOS 9.0+

## Installation

### Swift Package Manager

You can add `SwiftUIPagedScrolling` to an Xcode project by adding it as a package dependency.

1. From the **File** menu, select **Add Packages...**
2. Enter the repository URL: `https://github.com/NickTrienens2025/SwiftUIPagedScrolling`
3. Select the version requirements and target to add the package to.

## Usage

Here's an example of how to use `Pager`:

```swift
import SwiftUI
import SwiftUIPagedScrolling

struct ContentView: View {
    @State private var currentIndex = 0
    let items = ["Item 1", "Item 2", "Item 3", "Item 4"]

    var body: some View {
        Pager(
            pageCount: items.count,
            currentIndex: $currentIndex
        ) { index in
            Text(items[index])
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
        }
        .pagePadding(.horizontal, 20)
        .pageSpacing(10)
    }
}
```
## Gesture Coordination (Interactive Child Controls)

When placing interactive elements (like buttons) inside pager cells, dragging the pager can accidentally trigger the button's tap action when the user lifts their finger. This occurs because the parent pager uses a simultaneous gesture to coordinate with subview gestures.

To prevent this, `SwiftUIPagedScrolling` provides the `isDragging` state in the shared `PagerContext`. You can disable child buttons dynamically when a drag is active, which tells SwiftUI to instantly cancel any active touch tracking:

```swift
struct PagerCellView: View {
    let item: String
    @Environment(\.pagerContext) var pagerContext
    
    var body: some View {
        VStack {
            Text(item)
            
            Button("Action") {
                print("Tapped!")
            }
            .buttonStyle(.plain)
            .disabled(pagerContext?.isDragging ?? false) // Prevents tap during drag
        }
    }
}
```

## Nested ScrollViews (Same-Axis Side Scrolling)

If you place a horizontal `ScrollView` inside a horizontal pager, the pager's drag gesture will compete with the child `ScrollView`'s touch gesture. 

To resolve this conflict and allow the nested scroll view to scroll horizontally, apply the `.ignorePagerGesture()` view modifier to the inner scroll view. This tells the parent pager to ignore its own drag gestures when a horizontal drag is initiated on the nested scroll view:

```swift
struct PagerCellView: View {
    var body: some View {
        VStack {
            Text("Cell Content")
            
            // A horizontal scrolling list inside a horizontal pager
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(1...10, id: \.self) { i in
                        Text("Item \(i)")
                            .padding()
                            .background(Color.secondary.opacity(0.2))
                    }
                }
            }
            .ignorePagerGesture() // Allows side-scrolling inside the pager
        }
    }
}
```

## Running Examples

The `Examples` directory contains a sample application demonstrating different configurations and use-cases, including vertical layout examples and tabbed navigation structures.
