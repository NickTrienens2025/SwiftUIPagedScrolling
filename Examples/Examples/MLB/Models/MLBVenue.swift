import Foundation

/// Represents the physical location where an MLB game is played.
/// Marked as `Sendable` to ensure strict Swift 6 concurrency safety.
struct MLBVenue: Decodable, Sendable {
    /// The name of the venue or stadium.
    let name: String
}
