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

## Running Examples

The `Examples` directory contains a sample application demonstrating different configurations and use-cases, including vertical layout examples and tabbed navigation structures.
