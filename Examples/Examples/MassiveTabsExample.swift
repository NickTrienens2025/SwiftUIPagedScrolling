import SwiftUI
import SwiftUIPagedScrolling

struct MassiveTabsExample: View {
    @State private var currentIndex: Int = 0
    let pageCount = 300

    var body: some View {
        VStack {
            Text("Massive 300 Tabs Example")
                .font(.headline)
                .padding()

            Text("Rendering seamlessly O(1)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            SwiftUIPagedScrolling(
                pageCount: pageCount,
                currentIndex: $currentIndex
            ) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hue: Double(index) / Double(pageCount), saturation: 0.8, brightness: 0.8))

                    VStack {
                        Text("Day \(index)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        Text("Smooth Scroll")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
            }
            .pageSpacing(16)
            .frame(height: 400)

            VStack {
                Text("Jump Array Index")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Slider(value: Binding(
                    get: { Double(currentIndex) },
                    set: { newValue in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            currentIndex = Int(newValue)
                        }
                    }
                ), in: 0 ... Double(pageCount - 1), step: 1.0)
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)

            Spacer()
        }
    }
}
