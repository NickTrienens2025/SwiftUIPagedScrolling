import Foundation

/// An actor to safely manage background polling tasks, protecting the task state 
/// from being accessed concurrently by different parts of the application.
actor PollingCoordinator {
    private var tasks: [String: Task<Void, Never>] = [:]

    /// Starts a repeating polling task that executes the given action every 15 seconds.
    ///
    /// - Parameters:
    ///   - dateString: The key for the specific date being polled.
    ///   - action: The async, Sendable closure to execute on every interval.
    func startPolling(for dateString: String, action: @escaping @Sendable () async -> Void) {
        // Prevent duplicate tasks for the same date
        if tasks[dateString] != nil { return }
        
        let task = Task {
            while !Task.isCancelled {
                do {
                    // Poll every 15 seconds
                    try await Task.sleep(for: .seconds(15))
                } catch {
                    break // Exit the loop if cancelled during sleep
                }
                await action()
            }
        }
        tasks[dateString] = task
    }

    /// Stops any active polling task for the given date.
    ///
    /// - Parameter dateString: The key for the specific date to stop polling.
    func stopPolling(for dateString: String) {
        tasks[dateString]?.cancel()
        tasks[dateString] = nil
    }
}
