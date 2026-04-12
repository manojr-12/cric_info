import Foundation

class APIService {
    private static let baseURL = "http://127.0.0.1:3000"

    static func fetchMatches() async -> [MatchListItem] {
        guard let url = URL(string: "\(baseURL)/matches/live") else {
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return []
            }
            return try JSONDecoder().decode([MatchListItem].self, from: data)
        } catch {
            print("Fetch matches error:", error)
            return []
        }
    }

    static func setPreferredMatch(matchId: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/matches/preference") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["matchId": matchId])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return false
            }
            return (200...299).contains(http.statusCode)
        } catch {
            print("Set preferred match error:", error)
            return false
        }
    }

    static func fetchMatch(matchId: String) async -> MatchScore? {
        guard let encodedId = matchId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/matches/score?matchId=\(encodedId)") else {
            return nil
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }

            guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let payload = root["payload"] else {
                return nil
            }

            let payloadData = try JSONSerialization.data(withJSONObject: payload)
            let details = try JSONDecoder().decode(MatchResponse.self, from: payloadData)
            return details.toMatchScore()
        } catch {
            print("Fetch match score error:", error)
            return nil
        }
    }
}
