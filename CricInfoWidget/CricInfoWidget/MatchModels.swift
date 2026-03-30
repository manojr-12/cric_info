
import Foundation

// MARK: - Root

struct MatchResponse: Codable {
    let match: Match// move here
    let bestPerformance: BestPerformance?   // same issue
}

// MARK: - Match

struct Match: Codable {
    let status: String?
    let statusText: String
    let teams: [TeamWrapper]

    let liveInningPredictions: LiveInningPredictions?

    let statusData: StatusData?          // ✅ FIX: optional
    let liveInfo: LiveInfo?
}



struct StatusData: Codable {
    let statusTextLangData: StatusTextData?
}

struct StatusTextData: Codable {
    let currentRunRate: Double?
    let requiredRunrate: Double?

    let crr: Double?    // ✅ API variant
    let rrr: Double?    // ✅ API variant

    let requiredRuns: Int?
    let remainingBalls: Int?
}


struct LivePerformance: Codable {
    let batsmen: [LiveBatsman]
    let bowlers: [LiveBowler]
}

struct LiveBatsman: Codable {
    let player: Player
    let runs: Int
    let balls: Int
    let fours: Int
    let sixes: Int
    let strikerate: Double
}

struct LiveBowler: Codable {
    let player: Player
    let overs: Int
    let balls: Int
    let conceded: Int
    let wickets: Int
    let economy: Double
}



struct BestPerformance: Codable {
    let batsmen: [BestBatsman]
    let bowlers: [BestBowler]
}

struct BestBatsman: Codable {
    let player: Player
    let runs: Int
    let balls: Int
    let fours: Int?
    let sixes: Int?
    let strikerate: Double?
}

struct BestBowler: Codable {
    let player: Player
    let overs: Int?
    let balls: Int?
    let conceded: Int?
    let wickets: Int?
    let economy: Double?
}



struct Player: Codable {
    let longName: String
}

struct TeamWrapper: Codable {
    let team: TeamInfo
    let score: String?
}

struct TeamInfo: Codable {
    let longName: String
    let abbreviation: String
}

struct LiveInningPredictions: Codable {
    let winProbability: Double
}

struct LiveInfo: Codable {
    let currentRunRate: Double
    let requiredRunrate: Double
}



struct MatchScore {
    let team1: String
    let team1Score: String

    let team2: String
    let team2Score: String

    let status: String
    let equation: String
    let isMatchOver: Bool

    let currentRR: String
    let requiredRR: String

    let winProbability: String
    let lastOver: [String]

    let batters: [Batter]
    let bowlers: [Bowler]
}

struct Batter {
    let name: String
    let runs: Int
    let balls: Int
    let fours: Int
    let sixes: Int
    let strikeRate: Double
}

struct Bowler {
    let name: String
    let overs: Double
    let runs: Int
    let wickets: Int
    let economy: Double
}



extension MatchResponse {

    func toMatchScore() -> MatchScore {

        let t1 = match.teams[0]
        let t2 = match.teams[1]

        let isMatchOver = match.status == "RESULT"

        // MARK: - Batters
        let batters: [Batter]

        if isMatchOver, let perf = self.bestPerformance {  // self instead of match
            batters = perf.batsmen.prefix(2).map {
                Batter(
                    name: $0.player.longName,
                    runs: $0.runs,
                    balls: $0.balls,
                    fours: $0.fours ?? 0,
                    sixes: $0.sixes ?? 0,
                    strikeRate: $0.strikerate ?? 0
                )
            }
        }  else {
            batters = []
        }

        // MARK: - Bowlers
        func overs(from balls: Int) -> Double {
            let o = balls / 6
            let b = balls % 6
            return Double(o) + Double(b) / 10.0
        }

        let bowlers: [Bowler]

        if isMatchOver, let perf = self.bestPerformance {  // self instead of match
            bowlers = perf.bowlers.prefix(2).map {
                Bowler(
                    name: $0.player.longName,
                    overs: overs(from: $0.balls ?? 0),
                    runs: $0.conceded ?? 0,
                    wickets: $0.wickets ?? 0,
                    economy: $0.economy ?? 0
                )
            }
        }  else {
            bowlers = []
        }

        // MARK: - Run Rate
        let liveData = match.statusData?.statusTextLangData

        let currentRR = match.liveInfo?.currentRunRate
            ?? liveData?.currentRunRate
            ?? liveData?.crr
            ?? 0

        let requiredRR = match.liveInfo?.requiredRunrate
            ?? liveData?.requiredRunrate
            ?? liveData?.rrr
            ?? 0

        let equation = isMatchOver
            ? ""
            : "Need \(liveData?.requiredRuns ?? 0) runs in \(liveData?.remainingBalls ?? 0) balls"

        let winProb = match.liveInningPredictions?.winProbability ?? 0

        return MatchScore(
            team1: t1.team.longName,
            team1Score: t1.score ?? "-",
            team2: t2.team.longName,
            team2Score: t2.score ?? "Yet to bat",
            status: match.statusText,
            equation: equation,
            isMatchOver: isMatchOver,
            currentRR: String(format: "%.2f", currentRR),
            requiredRR: String(format: "%.2f", requiredRR),
            winProbability: "\(t1.team.abbreviation) \(Int(winProb))%",
            lastOver: ["1", ".", "2", "4", "1"],
            batters: batters,
            bowlers: bowlers
        )
    }
}
