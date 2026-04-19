import SwiftUI
import SwiftUIPagedScrolling

struct BasicColorsExample: View {
    @State private var currentIndex: Int = 0
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]

    var body: some View {
        VStack {
            Text("Tabbed Scroll View Example")
                .font(.headline)
                .padding()

            SwiftUIPagedScrolling(
                pageCount: colors.count,
                currentIndex: $currentIndex
            ) { index in
                // Content
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colors[index])
                    Text("Page \(index)")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
                .padding()
            }
            .pageSpacing(16)
            .frame(height: 400)

            // Tab bar
            HStack {
                ForEach(0 ..< colors.count, id: \.self) { index in
                    Button(action: {
                        withAnimation {
                            currentIndex = index
                        }
                    }) {
                        Circle()
                            .fill(currentIndex == index ? colors[index] : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                    .accessibilityHidden(true)
                }
            }
            .padding(.top, 20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page controls")
            .accessibilityValue("Page \(currentIndex + 1) of \(colors.count)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    if currentIndex < colors.count - 1 { withAnimation { currentIndex += 1 } }
                case .decrement:
                    if currentIndex > 0 { withAnimation { currentIndex -= 1 } }
                @unknown default:
                    break
                }
            }

            Spacer()
        }
    }
}
