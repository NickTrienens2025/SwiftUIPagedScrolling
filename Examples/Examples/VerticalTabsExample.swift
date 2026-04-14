import SwiftUI
import SwiftUIPagedScrolling

struct VerticalTabsExample: View {
    @State private var currentIndex: Int = 0
    let colors: [Color] = [.purple, .indigo, .blue, .teal, .green]

    var body: some View {
        VStack {
            Text("Vertical Pager")
                .font(.largeTitle.bold())
                .padding(.top, 20)

            Text("Scroll Up and Down")
                .foregroundColor(.secondary)

            SwiftUIPagedScrolling(
                pageCount: colors.count,
                currentIndex: $currentIndex
            ) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(colors[index].gradient)

                    VStack(spacing: 12) {
                        Image(systemName: "arrow.up.and.down.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)

                        Text("Card \(index + 1)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
            }
            .pageSpacing(20)
            .pageOrientation(.vertical)

            HStack(spacing: 12) {
                ForEach(0 ..< colors.count, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? colors[index] : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .scaleEffect(currentIndex == index ? 1.2 : 1.0)
                        .animation(.spring(), value: currentIndex)
                }
            }
            .padding(.vertical, 20)
        }
    }
}
