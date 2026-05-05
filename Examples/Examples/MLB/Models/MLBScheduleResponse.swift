import Foundation

/// The top-level response from the MLB Schedule API.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBScheduleResponse: Decodable, Sendable {
    /// The schedule data grouped by date.
    let dates: [MLBDateData]
}

/// Contains all scheduled games for a specific date.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBDateData: Decodable, Sendable {
    /// The formatted date string (e.g., "2024-05-15")
    let date: String
    /// The array of games scheduled for this date
    let games: [MLBGame]
}
