# Display Zoom and Accessibility in Custom SwiftUI Pagers

## The Impact of iOS Display Zoom

When a user enables "Display Zoom" (often presented as "Zoomed" vs. "Standard" in iOS Settings), the OS simulates the screen dimensions of a smaller device. It physically magnifies UI elements by altering the logical point space coordinates.

### How Display Zoom Breaks Calculations

1. **`UIScreen.main.bounds` Becomes Unreliable:** 
   The most common error in manual UI scaling comes from reading `UIScreen.main.bounds.width` or `height`. When Display Zoom is on, `main.bounds` reports a smaller width/height in points. If a custom pager or swipe component uses hardcoded multipliers or fixed threshold sizes based on a standard point mapping (e.g. `if drag.translation > 100 points`), it might suddenly require disproportionately larger or smaller swipes under Display Zoom text limits.
2. **Horizontal Offsets and Framing:**
   If components rely on padding offsets derived from assumed physical characteristics (like assuming the device is *always* 390pt wide, or calculating device-specific offsets instead of using `GeometryReader`), pages will be improperly anchored.

### Best Practices

- **Never Use Global Bounds:** Abandon `UIScreen.main.bounds`.
- **Use `GeometryReader` Extensively:** Ensure that layout constraints rely entirely on the dynamic size provided by a parent `GeometryProxy`. This guarantees that if iOS decides to scale points due to Display Zoom or Split View multitasking, the UI reacts to the actual available rendering space.

---

## Assuring Accessibility for Pager Interfaces

Custom Pagers, especially those built on top of `DragGesture` applied to an `HStack`, are essentially invisible to Apple's native VoiceOver engine for pagination.

### 1. Navigating via VoiceOver Gestures
Standard users swipe to pan. VoiceOver users flick left/right to move focus between elements, and use a **three-finger horizontal swipe** to simulate scrolling a page. If standard `ScrollView` with `.pagingIdentifier` isn't used, these gestures fall dead.

**Solution:** Add `.accessibilityScrollAction` interceptors on the view.

```swift
.accessibilityScrollAction { edge in
    switch edge {
    case .leading:
        // User swiped down/right - move back a page
        previousPage()
    case .trailing:
        // User swiped up/left - advance a page
        nextPage()
    default: break
    }
}
```

### 2. Communicating Component Intent
Add `.accessibilityAddTraits(.isScrollable)` and `.accessibilityValue("Page X of Y")`. VoiceOver may not organically understand that the full frame is a "Pager" if you built it using nested ZStacks and offsets.

### 3. Dynamic Type Integration
When a user sets their iPhone to a very high default text scale, paginated elements specifically risk layout explosions as text expands vertically, potentially exceeding the hard limits of a screen. 

When building Pager wrappers or Views that reside *within* the pages:
- Do not constrain `VStack` frames without `.frame(minHeight: ...)` or similar allowances.
- Encapsulate the `Pager` content item in a vertical `.scrollable` wrapper if its view demands text that runs the risk of exceeding the viewport height.

## Summary

Always structure a custom Pager with **relative metrics** (`GeometryReader` size data) instead of absolute constants, and manually link the interface logic back to **VoiceOver system actions** using `accessibilityScrollAction`. This achieves 100% Display Zoom and standard Accessibility parity out of the box.
