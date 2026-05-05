import SwiftUI
import SwiftUIPagedScrolling

/// The main view for displaying a list of scheduled MLB games for a given date.
struct MLBDailyGamesView: View {
    /// The date for which to display the schedule.
    let date: Date
    
    /// The globally accessible schedule store that manages data fetching and caching.
    @EnvironmentObject var store: MLBScheduleStore

    /// The formatted date string used as a key in the store's cache.
    private var dateKey: String {
        store.formattedDate(date)
    }

    /// The current loading state for the games on this date.
    private var state: LoadingState<[MLBGame]>? {
        store.gamesByDate[dateKey]
    }

    var body: some View {
        ZStack {
            Color(UIColor.secondarySystemBackground)

            VStack(spacing: 20) {
                HStack {
                    Text(date.formatted(date: .long, time: .omitted))
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Spacer()

                    // Show a spinner if actively loading or waiting for the initial state.
                    if case .loading = state {
                        ProgressView()
                    } else if state == nil {
                        ProgressView()
                    }
                }

                switch state {
                case let .success(games):
                    if games.isEmpty {
                        Spacer()
                        Text("No scheduled games.")
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                // Sort games so that Live games appear at the top
                                let sortedGames = games.sorted {
                                    if $0.status.abstractGameState == "Live" && $1.status.abstractGameState != "Live" { return true }
                                    if $0.status.abstractGameState != "Live" && $1.status.abstractGameState == "Live" { return false }
                                    return false
                                }
                                ForEach(sortedGames) { game in
                                    MLBGameCardView(game: game)
                                }
                                Spacer()
                                    .frame(height: 100)
                            }
                        }
                    }
                case let .error(error):
                    Spacer()
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                    Spacer()
                case .loading, .none:
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
            .padding()
        }
        .onAppear {
            print("📊 [\\(Date().formatted(date: .omitted, time: .standard))] MLBDailyGamesView loaded for date: \\(dateKey)")
            // Initiate data loading when this view segment appears using a standard detached Task
            Task {
                await store.fetchGames(for: date)
            }
        }
    }
}
