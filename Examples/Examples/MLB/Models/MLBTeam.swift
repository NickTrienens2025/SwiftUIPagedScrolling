import Foundation

/// A container for both teams participating in a game.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBTeams: Decodable, Sendable {
    /// The away team.
    let away: MLBTeamStatus
    /// The home team.
    let home: MLBTeamStatus
}

/// The state of a specific team within a game context (including their score).
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBTeamStatus: Decodable, Sendable {
    /// The underlying team identity.
    let team: MLBTeam
    /// The current score of the team, if available.
    let score: Int?
    /// Whether this team is currently marked as the winner.
    let isWinner: Bool?
}

/// The basic informational model of an MLB team.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBTeam: Decodable, Sendable {
    /// The unique identifier for the team.
    let id: Int
    /// The full name of the team.
    let name: String

    /// Computes the URL for the team's logo image from the MLB static assets endpoint.
    var logoURL: URL? {
        URL(string: "https://midfield.mlbstatic.com/v1/team/\(id)/spots/72")
    }
}
