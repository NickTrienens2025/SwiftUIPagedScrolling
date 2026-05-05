import Foundation

/// Represents the top-level live feed response containing granular, in-game data.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBLiveFeed: Decodable, Equatable, Hashable, Sendable {
    /// The core payload of live data.
    let liveData: MLBLiveData
}

/// Contains the specific real-time play and scoring details of a game.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBLiveData: Decodable, Equatable, Hashable, Sendable {
    /// Information regarding the current inning, balls, strikes, and outs.
    let linescore: MLBLinescore?
    
    /// Information regarding the winning, losing, and saving pitchers for completed games.
    let decisions: MLBDecisions?
}

/// Records the official pitching decisions for a finalized game.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBDecisions: Decodable, Equatable, Hashable, Sendable {
    /// The pitcher who was awarded the win.
    let winner: MLBPlayerRef?
    /// The pitcher who was handed the loss.
    let loser: MLBPlayerRef?
    /// The pitcher who recorded the save (if applicable).
    let save: MLBPlayerRef?
}

/// Detailed line score information for a live game.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBLinescore: Decodable, Equatable, Hashable, Sendable {
    /// The current inning number.
    let currentInning: Int?
    /// The state of the inning (e.g., "Top", "Bottom", "Middle").
    let inningState: String?
    /// The half of the inning ("Top" or "Bottom").
    let inningHalf: String?
    /// The current count of balls for the active batter.
    let balls: Int?
    /// The current count of strikes for the active batter.
    let strikes: Int?
    /// The current number of outs in the half-inning.
    let outs: Int?
    /// Offensive stats and active players (like the current batter).
    let offense: MLBTeamStats?
    /// Defensive stats and active players (like the current pitcher).
    let defense: MLBTeamStats?
}

/// Active participants for a specific team during a live play.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBTeamStats: Decodable, Equatable, Hashable, Sendable {
    /// A reference to the active batter.
    let batter: MLBPlayerRef?
    /// A reference to the active pitcher.
    let pitcher: MLBPlayerRef?
    
    /// Reference to the player on first base.
    let first: MLBPlayerRef?
    /// Reference to the player on second base.
    let second: MLBPlayerRef?
    /// Reference to the player on third base.
    let third: MLBPlayerRef?
}

/// A lightweight reference to an MLB player.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBPlayerRef: Decodable, Equatable, Hashable, Sendable {
    /// The full name of the player.
    let fullName: String
}
