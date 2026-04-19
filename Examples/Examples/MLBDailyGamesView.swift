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
                                let sortedGames = games.sorted {
                                    if $0.status.abstractGameState == "Live" && $1.status.abstractGameState != "Live" { return true }
                                    if $0.status.abstractGameState != "Live" && $1.status.abstractGameState == "Live" { return false }
                                    return false
                                }
                                ForEach(sortedGames) { game in
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
            
            if game.status.abstractGameState == "Final" {
                if let decisions = game.liveDetail?.liveData.decisions {
                    Divider()
                    decisionsRow(decisions: decisions)
                }
            } else if let linescore = game.liveDetail?.liveData.linescore {
                Divider()
                liveDetailRow(detail: linescore)
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func liveDetailRow(detail: MLBLinescore) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let inning = detail.currentInning, let state = detail.inningState {
                    Text("\(state) \(inning)")
                        .font(.caption.bold())
                }
                if let outs = detail.outs {
                    Text("\(outs) Outs")
                        .font(.caption2)
                }
                if let balls = detail.balls, let strikes = detail.strikes {
                    Text("\(balls) - \(strikes)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let pitcher = detail.defense?.pitcher?.fullName {
                    Text("P: \(pitcher)")
                        .font(.caption)
                }
                if let batter = detail.offense?.batter?.fullName {
                    Text("B: \(batter)")
                        .font(.caption)
                }
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func decisionsRow(decisions: MLBDecisions) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let winner = decisions.winner?.fullName {
                    Text("W: \(winner)")
                        .font(.caption)
                }
                if let loser = decisions.loser?.fullName {
                    Text("L: \(loser)")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let save = decisions.save?.fullName {
                    Text("S: \(save)")
                        .font(.caption)
                }
            }
        }
        .padding(.top, 4)
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
