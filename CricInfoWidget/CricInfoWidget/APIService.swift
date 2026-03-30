import Foundation

class APIService {
    
    static func fetchMatch() async -> MatchScore? {
        guard let url = URL(string: "http://127.0.0.1:3000/matches/score?matchId=1527676") else {
            return nil
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(MatchResponse.self, from: data)
            return result.toMatchScore()
            
        } catch {
            print("API Error:", error)
            return nil
        }
    }
}


func startPolling() {
    Task {
        while true {
            let start = Date()

            if let match = await APIService.fetchMatch() {
                print("Updated match:", match)
            }

            let elapsed = Date().timeIntervalSince(start)
            print("⏱ API + processing time: \(elapsed) sec")

            try? await Task.sleep(nanoseconds: 25 * 1_000_000_000)
        }
    }
}
