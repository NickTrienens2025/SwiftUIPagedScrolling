import SwiftUI
import Combine

/// The main view model responsible for providing MLB schedule data to the SwiftUI views.
/// Marked as `@MainActor` to ensure all UI updates are performed safely on the main thread.
@MainActor
class MLBScheduleStore: ObservableObject {
    
    /// A dictionary mapping formatted date strings to the loading state of games for that date.
    @Published var gamesByDate: [String: LoadingState<[MLBGame]>] = [:]

    /// A date formatter for converting Date objects into "yyyy-MM-dd" strings used by the API.
    private let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    /// Our Sendable networking repository that caches and manages the games.
    private let repository = MLBRepository()
    
    /// Internal actor to track polling tasks safely off the main thread
    private let pollingCoordinator = PollingCoordinator()

    /// Entry point to fetch games for a specific date. If data is already cached, it skips the initial fetch
    /// but ensures the live polling loop is active if needed.
    ///
    /// - Parameter date: The specific date to fetch the schedule for.
    func fetchGames(for date: Date) async {
        let dateString = formatter.string(from: date)

        if let existing = gamesByDate[dateString] {
            switch existing {
            case .loading, .success:
                // We've already started loading or have data.
                // Just make sure polling is active if needed.
                startPollingIfNecessary(for: dateString)
                return 
            case .error:
                break // Allow retry on error
            }
        }

        gamesByDate[dateString] = .loading

        do {
            // Use the repository to perform the network request
            let games = try await repository.fetchGames(for: dateString)
            gamesByDate[dateString] = .success(games)
            
            // Sequentially trigger live detail fetches for the games to populate balls/strikes
            await fetchLiveDetails(for: games, dateString: dateString)
            
            // Start internal polling to keep live games updated automatically
            startPollingIfNecessary(for: dateString)
        } catch {
            print("❌ [\(Date().formatted(date: .omitted, time: .standard))] Failed to fetch MLB matches for \(dateString): \(error)")
            gamesByDate[dateString] = .error(error)
        }
    }
    
    /// Starts an internal background task to poll for live game updates if there are games that are not yet final.
    private func startPollingIfNecessary(for dateString: String) {
        Task {
            await pollingCoordinator.startPolling(for: dateString) { [weak self] in
                guard let self = self else { return }
                await self.performPoll(for: dateString)
            }
        }
    }
    
    /// Executes a single poll iteration, updating games and live details.
    private func performPoll(for dateString: String) async {
        do {
            print("🔄 [\(Date().formatted(date: .omitted, time: .standard))] Polling live updates for \(dateString)")
            
            // 1. Fetch the latest high-level schedule to get updated scores and statuses.
            // The repository now manages the merge logic internally.
            let updatedGames = try await repository.fetchGames(for: dateString)
            
            // If all games are final, we can stop polling for this date to save resources.
            let allFinal = updatedGames.allSatisfy { $0.status.abstractGameState == "Final" }
            if allFinal && !updatedGames.isEmpty {
                print("🛑 [\(Date().formatted(date: .omitted, time: .standard))] All games final for \(dateString). Stopping poll.")
                await pollingCoordinator.stopPolling(for: dateString)
            }
            
            // 2. Publish the updated schedule to the UI. Since the repository is stateless, we merge existing live details manually.
            if case .success(let currentGames) = gamesByDate[dateString] {
                var mergedGames = updatedGames
                for i in mergedGames.indices {
                    if let existingGame = currentGames.first(where: { $0.gamePk == mergedGames[i].gamePk }) {
                        mergedGames[i].liveDetail = existingGame.liveDetail
                    }
                }
                
                withAnimation(.spring) {
                    gamesByDate[dateString] = .success(mergedGames)
                }
            } else {
                withAnimation(.spring) {
                    gamesByDate[dateString] = .success(updatedGames)
                }
            }
            
            // 3. Fetch granular live details (balls, strikes, innings) for any games currently 'Live'
            await fetchLiveDetails(for: updatedGames, dateString: dateString)
            
        } catch {
            print("⚠️ [\(Date().formatted(date: .omitted, time: .standard))] Poll failed for \(dateString): \(error.localizedDescription)")
        }
    }
    
    /// Fetches live details for all provided games sequentially.
    private func fetchLiveDetails(for games: [MLBGame], dateString: String) async {
        // Only fetch live details for games that are actually live or final
        let gamesToFetch = games.filter {
            $0.status.abstractGameState == "Live" || $0.status.abstractGameState == "Final"
        }
        
        for game in gamesToFetch {
            do {
                let detail = try await repository.fetchLiveDetail(for: game.gamePk)
                
                // Mutate state with animation to visually append/update row details smoothly
                if case .success(var currentGames) = gamesByDate[dateString],
                   let index = currentGames.firstIndex(where: { $0.gamePk == game.gamePk }) {
                    
                    // Only update if the details actually changed to prevent excessive redraws
                    if currentGames[index].liveDetail != detail {
                        withAnimation(.spring) {
                            currentGames[index].liveDetail = detail
                            gamesByDate[dateString] = .success(currentGames)
                        }
                    }
                }
            } catch {
                print("❌ [\\(Date().formatted(date: .omitted, time: .standard))] Failed to fetch live detail for game \\(game.gamePk): \\(error.localizedDescription)")
            }
        }
    }

    /// Formats a date into a key used for API fetching and caching.
    /// - Parameter date: The date to format.
    /// - Returns: A string in "yyyy-MM-dd" format.
    func formattedDate(_ date: Date) -> String {
        formatter.string(from: date)
    }
}
