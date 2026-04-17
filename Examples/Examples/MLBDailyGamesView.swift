import SwiftUI
import SwiftUIPagedScrolling

struct MLBDailyGamesView: View {
    let date: Date
    @EnvironmentObject var store: MLBScheduleStore

    private var dateKey: String {
        store.formattedDate(date)
    }

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
                                ForEach(games) { game in
                                    gameCard(for: game)
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
        .task {
            print("📊 [\(Date().formatted(date: .omitted, time: .standard))] MLBDailyGamesView loaded for date: \(dateKey)")
            // Initiate data loading when this view segment appears.
            await store.fetchGames(for: date)
        }
    }

    private let mockRoster = [
        "J. Smith", "A. Judge", "M. Trout", "S. Ohtani", "F. Freeman", "M. Betts",
        "R. Acuna", "J. Soto", "C. Bellinger", "G. Cole"
    ]

    @ViewBuilder
    private func gameCard(for game: MLBGame) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(game.status.detailedState)
                    .font(.caption.bold())
                    .foregroundColor(game.status.abstractGameState == "Live" ? .red : .secondary)
                Spacer()
                Text(game.venue.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Divider()
            teamRow(teamStatus: game.teams.away)
            teamRow(teamStatus: game.teams.home)
            
            Divider()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(mockRoster, id: \.self) { player in
                        Text(player)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
            .ignorePagerGesture()
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func teamRow(teamStatus: MLBTeamStatus) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: teamStatus.team.logoURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Circle()
                    .fill(Color.secondary.opacity(0.2))
            }
            .frame(width: 30, height: 30)

            Text(teamStatus.team.name)
                .font(.headline)
                .fontWeight(teamStatus.isWinner == true ? .bold : .regular)
            Spacer()
            if let score = teamStatus.score {
                Text("\(score)")
                    .font(.title3)
                    .fontWeight(teamStatus.isWinner == true ? .bold : .regular)
            } else {
                Text("-")
                    .foregroundColor(.secondary)
            }
        }
    }
}
