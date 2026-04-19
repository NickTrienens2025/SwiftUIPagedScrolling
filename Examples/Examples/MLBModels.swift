import Combine
import Foundation
import SwiftUI

// MARK: - API Response Models

struct MLBScheduleResponse: Decodable {
    let dates: [MLBDateData]
}

struct MLBDateData: Decodable {
    let date: String
    let games: [MLBGame]
}

struct MLBGame: Decodable, Identifiable, Hashable {
    let gamePk: Int
    var id: Int { gamePk }
    let status: MLBGameStatus
    let teams: MLBTeams
    let venue: MLBVenue
    var liveDetail: MLBLiveFeed?

    static func == (lhs: MLBGame, rhs: MLBGame) -> Bool {
        lhs.gamePk == rhs.gamePk && lhs.liveDetail == rhs.liveDetail
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(gamePk)
    }
}

struct MLBGameStatus: Decodable {
    let abstractGameState: String
    let detailedState: String
}

struct MLBTeams: Decodable {
    let away: MLBTeamStatus
    let home: MLBTeamStatus
}

struct MLBTeamStatus: Decodable {
    let team: MLBTeam
    let score: Int?
    let isWinner: Bool?
}

struct MLBTeam: Decodable {
    let id: Int
    let name: String

    var logoURL: URL? {
        URL(string: "https://midfield.mlbstatic.com/v1/team/\(id)/spots/72")
    }
}

struct MLBVenue: Decodable {
    let name: String
}

// MARK: - Live Details Response Models

struct MLBLiveFeed: Decodable, Equatable, Hashable {
    let liveData: MLBLiveData
}

struct MLBLiveData: Decodable, Equatable, Hashable {
    let linescore: MLBLinescore?
    let decisions: MLBDecisions?
}

struct MLBDecisions: Decodable, Equatable, Hashable {
    let winner: MLBPlayerRef?
    let loser: MLBPlayerRef?
    let save: MLBPlayerRef?
}

struct MLBLinescore: Decodable, Equatable, Hashable {
    let currentInning: Int?
    let inningState: String?
    let inningHalf: String?
    let balls: Int?
    let strikes: Int?
    let outs: Int?
    let offense: MLBTeamStats?
    let defense: MLBTeamStats?
}

struct MLBTeamStats: Decodable, Equatable, Hashable {
    let batter: MLBPlayerRef?
    let pitcher: MLBPlayerRef?
}

struct MLBPlayerRef: Decodable, Equatable, Hashable {
    let fullName: String
}

// MARK: - Loading State

enum LoadingState<T> {
    case loading
    case success(T)
    case error(Error)
}

// MARK: - MVVM Store (Global Cache)

@MainActor
class MLBScheduleStore: ObservableObject {
    @Published var gamesByDate: [String: LoadingState<[MLBGame]>] = [:]

    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    func fetchGames(for date: Date) async {
        let dateString = formatter.string(from: date)

        if let existing = gamesByDate[dateString] {
            switch existing {
            case .loading, .success:
                return // If already cached or currently loading, skip to prevent redundant calls.
            case .error:
                break // Allow retry on error
            }
        }

        print("🌐 [\(Date().formatted(date: .omitted, time: .standard))] Fetching MLB games for date: \(dateString)")
        let fetchStartTime = Date()

        gamesByDate[dateString] = .loading

        guard let url = URL(string: "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=\(dateString)") else {
            gamesByDate[dateString] = .error(URLError(.badURL))
            return 
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(MLBScheduleResponse.self, from: data)

            let games = response.dates.first?.games ?? []
            gamesByDate[dateString] = .success(games)
            
            let duration = Date().timeIntervalSince(fetchStartTime)
            print("✅ [\(Date().formatted(date: .omitted, time: .standard))] Successfully fetched data for \(dateString) in \(String(format: "%.3f", duration))s \(url)")
            
            // Sequentially trigger live detail fetches for the games top down to animate updates
            Task {
                for game in games {
                    await fetchLiveDetail(for: game.gamePk, dateString: dateString)
                }
            }
        } catch {
            let duration = Date().timeIntervalSince(fetchStartTime)
            print("❌ [\(Date().formatted(date: .omitted, time: .standard))] Failed to fetch MLB matches for \(dateString) after \(String(format: "%.3f", duration))s: \(error)")
            gamesByDate[dateString] = .error(error)
        }
    }
    
    private func fetchLiveDetail(for gamePk: Int, dateString: String) async {
        guard let url = URL(string: "https://statsapi.mlb.com/api/v1.1/game/\(gamePk)/feed/live") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let detail = try JSONDecoder().decode(MLBLiveFeed.self, from: data)
            
            // Mutate state with animation to visually append row details smoothly
            if case .success(var currentGames) = gamesByDate[dateString],
               let index = currentGames.firstIndex(where: { $0.gamePk == gamePk }) {
                withAnimation(.spring) {
                    currentGames[index].liveDetail = detail
                    gamesByDate[dateString] = .success(currentGames)
                }
            }
        } catch {
            print("❌ [\(Date().formatted(date: .omitted, time: .standard))] Failed to fetch live detail for game \(gamePk): \(error)")
        }
    }

    func formattedDate(_ date: Date) -> String {
        formatter.string(from: date)
    }
}
