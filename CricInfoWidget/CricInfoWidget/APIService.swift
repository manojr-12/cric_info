import Foundation

class APIService {
    
    static func fetchMatch() async -> MatchScore? {
        guard let url = URL(string: "http://127.0.0.1:3000/matches/score?matchId=1527675") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print("RAW JSON 👇")
            print(String(data: data, encoding: .utf8) ?? "nil")
            let decoder = JSONDecoder()
            //let response = try decoder.decode(MatchResponse.self, from: data)
            do {
                let result = try JSONDecoder().decode(MatchResponse.self, from: data)
                print("✅ Success")
                return result.toMatchScore()
                
            } catch let DecodingError.typeMismatch(type, context) {
                print("❌ Type mismatch:", type)
                print("📍 Path:", context.codingPath.map { $0.stringValue })
                print("🧾 Description:", context.debugDescription)
            } catch let DecodingError.valueNotFound(type, context) {
                print("❌ Value not found:", type)
                print("📍 Path:", context.codingPath.map { $0.stringValue })
            } catch let DecodingError.keyNotFound(key, context) {
                print("❌ Key not found:", key)
                print("📍 Path:", context.codingPath.map { $0.stringValue })
            } catch {
                print("❌ Other error:", error)
            }
            return nil;
            
        } catch {
            print("API Error:", error)
            return nil
        }
    }
}
