import Foundation
import Combine

@MainActor
class ScoreViewModel: ObservableObject {
    @Published var score: MatchScore?

    private var pollingTask: Task<Void, Never>?

    init() {
        startPolling()
    }

    func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                if let result = await APIService.fetchMatch() {
                    self.score = result
                }

                try? await Task.sleep(nanoseconds: 25 * 1_000_000_000)
            }
        }
    }

    deinit {
        pollingTask?.cancel()
    }
}
