import Foundation
import Combine

@MainActor
class ScoreViewModel: ObservableObject {
    @Published var score: MatchScore?

    init() {
        Task {
            await fetch()
        }
    }

    func fetch() async {
        if let result = await APIService.fetchMatch() {
            self.score = result
        }
    }
}
