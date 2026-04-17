import SwiftUI
import SwiftUIPagedScrolling

struct DateTabsExample: View {
    @State private var currentIndex: Int = 0
    @State private var dates: [Date] = []
    @StateObject private var store = MLBScheduleStore()

    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "E MMM d"
        return df
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Date Tab Bar
            if !dates.isEmpty {
                dateBar()

                // Content View
                SwiftUIPagedScrolling(
                    pageCount: dates.count,
                    currentIndex: $currentIndex
                ) { index in
                    MLBDailyGamesView(date: dates[index])
                }
                .pageSpacing(1)
                .pagerGesturePriority(.simultaneous)
                .environmentObject(store)
                .ignoresSafeArea(edges: .bottom)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if dates.isEmpty {
                setupDates()
            }
        }
    }

    @ViewBuilder
    private func dateBar() -> some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 20) {
                    ForEach(0 ..< dates.count, id: \.self) { index in
                        let date = dates[index]
                        let isSelected = currentIndex == index

                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Text(dateFormatter.string(from: date))
                                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(isSelected ? .primary : .secondary)

                                if case let .success(games) = store.gamesByDate[store.formattedDate(date)] {
                                    Text("\(games.count)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(games.isEmpty ? Color.gray : Color.blue)
                                        .clipShape(Capsule())
                                }
                            }

                            // Underline
                            Rectangle()
                                .fill(isSelected ? Color.primary : Color.clear)
                                .frame(height: 3)
                        }
                        .padding(.horizontal, 4)
                        .id(index)
                        .onTapGesture {
                            withAnimation {
                                currentIndex = index
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: currentIndex) { newIndex in
                withAnimation {
                    scrollProxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    scrollProxy.scrollTo(currentIndex, anchor: .center)
                }
            }
        }
        .frame(height: 50)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
        .zIndex(1)
    }

    func setupDates() {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())

        guard let startOfLastYear = calendar.date(from: DateComponents(year: year - 1, month: 1, day: 1)),
              let endOfThisYear = calendar.date(from: DateComponents(year: year, month: 12, day: 31)) else { return }

        var generatedDates = [Date]()
        var currentDate = startOfLastYear

        while currentDate <= endOfThisYear {
            generatedDates.append(currentDate)
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }

        dates = generatedDates

        // Find today
        if let todayIdx = generatedDates.firstIndex(where: { calendar.isDateInToday($0) }) {
            currentIndex = todayIdx
        }
    }
}
