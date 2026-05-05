import Foundation

/// Represents a single MLB game with its status, teams, and live details.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBGame: Decodable, Identifiable, Hashable, Sendable {
    /// The unique identifier for the game provided by the MLB API.
    let gamePk: Int
    
    /// Conformance to `Identifiable`.
    var id: Int { gamePk }
    
    /// The current status of the game (e.g., Live, Final).
    let status: MLBGameStatus
    
    /// The home and away teams involved in the game.
    let teams: MLBTeams
    
    /// The venue where the game is being played.
    let venue: MLBVenue
    
    /// Optional live feed details containing granular play-by-play info like balls and strikes.
    /// This property is mutable so it can be updated incrementally via polling without re-fetching everything.
    var liveDetail: MLBLiveFeed?

    /// Checks equality based on the unique game identifier and the current live details.
    static func == (lhs: MLBGame, rhs: MLBGame) -> Bool {
        lhs.gamePk == rhs.gamePk && lhs.liveDetail == rhs.liveDetail
    }

    /// Hashes the game purely based on its primary key.
    func hash(into hasher: inout Hasher) {
        hasher.combine(gamePk)
    }
}

/// Represents the high-level scheduling status of a game.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBGameStatus: Decodable, Sendable {
    /// A broad state category (e.g., "Live", "Final", "Preview").
    let abstractGameState: String
    
    /// A more descriptive state string (e.g., "In Progress", "Final").
    let detailedState: String
}
