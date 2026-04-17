import Combine
import Foundation

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

    static func == (lhs: MLBGame, rhs: MLBGame) -> Bool {
        lhs.gamePk == rhs.gamePk
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

            gamesByDate[dateString] = .success(response.dates.first?.games ?? [])
            
            let duration = Date().timeIntervalSince(fetchStartTime)
            print("✅ [\(Date().formatted(date: .omitted, time: .standard))] Successfully fetched data for \(dateString) in \(String(format: "%.3f", duration))s \(url)")
        } catch {
            let duration = Date().timeIntervalSince(fetchStartTime)
            print("❌ [\(Date().formatted(date: .omitted, time: .standard))] Failed to fetch MLB matches for \(dateString) after \(String(format: "%.3f", duration))s: \(error)")
            gamesByDate[dateString] = .error(error)
        }
    }

    func formattedDate(_ date: Date) -> String {
        formatter.string(from: date)
    }
}
