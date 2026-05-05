import Foundation

/// A stateless repository responsible for handling all MLB data network requests.
/// Implemented as a struct conforming to Sendable to ensure strict Swift 6 concurrency safety.
struct MLBRepository: Sendable {
    
    /// Fetches all scheduled MLB games for a given date.
    ///
    /// - Parameter dateString: The formatted date string (e.g., "yyyy-MM-dd") to fetch games for.
    /// - Returns: An array of `MLBGame` objects.
    /// - Throws: An error if the network request or decoding fails.
    func fetchGames(for dateString: String) async throws -> [MLBGame] {
        // Construct the URL to the MLB Schedule API. We use sportId=1 for Major League Baseball.
        guard let url = URL(string: "https://statsapi.mlb.com/api/v1/schedule?sportId=1&date=\(dateString)") else {
            throw URLError(.badURL)
        }
        
        let fetchStartTime = Date()
        print("🌐 [\(Date().formatted(date: .omitted, time: .standard))] Repository fetching MLB games for date: \(dateString)")
        
        // Await the network response
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Decode the JSON data into our Sendable MLB models
        let response = try JSONDecoder().decode(MLBScheduleResponse.self, from: data)
        let duration = Date().timeIntervalSince(fetchStartTime)
        print("✅ [\(Date().formatted(date: .omitted, time: .standard))] Successfully fetched schedule for \(dateString) in \(String(format: "%.3f", duration))s")
        
        // Extract the games for the first matching date
        return response.dates.first?.games ?? []
    }
    
    /// Fetches live, detailed, in-game data for a specific game.
    ///
    /// - Parameter gamePk: The unique identifier for the game.
    /// - Returns: An `MLBLiveFeed` object containing the detailed play-by-play data.
    /// - Throws: An error if the network request or decoding fails.
    func fetchLiveDetail(for gamePk: Int) async throws -> MLBLiveFeed {
        // Construct the URL to the MLB Live Game Feed API.
        guard let url = URL(string: "https://statsapi.mlb.com/api/v1.1/game/\(gamePk)/feed/live") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)

        // Decode the live feed details
        return try JSONDecoder().decode(MLBLiveFeed.self, from: data)
    }
}
