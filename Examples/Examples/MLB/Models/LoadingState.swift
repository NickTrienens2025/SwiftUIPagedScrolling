import Foundation

/// A generic enum representing the asynchronous loading state of a resource.
/// By enforcing `T: Sendable` and marking the enum as `Sendable`, it is fully
/// compatible with Swift 6 strict concurrency checks and can cross actor boundaries.
enum LoadingState<T: Sendable>: Sendable {
    /// The resource is currently being fetched or processed.
    case loading
    
    /// The resource was successfully loaded.
    case success(T)
    
    /// An error occurred during fetching or processing.
    case error(Error)
    
    /// A convenience property to extract the underlying value if the state is `.success`.
    var value: T? {
        if case let .success(val) = self {
            return val
        }
        return nil
    }
}
