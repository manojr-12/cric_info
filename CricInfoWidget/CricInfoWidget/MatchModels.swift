
import Foundation

// MARK: - Root

struct MatchResponse: Codable {
    let match: Match
    let livePerformance: LivePerformance?
    let bestPerformance: BestPerformance?
    let recentBallCommentary: RecentBallCommentary?
    let supportInfo: SupportInfo?
    
}

struct SupportInfo: Codable {
    let liveInfo: LiveInfo?
    let liveSummary: LiveSummary?
    
}


struct LiveSummary: Codable {
    let recentBalls: [Ball]
}

struct Ball: Codable {
    let overNumber: Int
    let ballNumber: Int
    let totalRuns: Int
    let isWicket: Bool
    let wides: Int
    let noballs: Int
    let batsmanPlayerId: Int
    let bowlerPlayerId: Int
}

struct LiveInfo: Codable {
    let type: String?
    let currentRunRate: Double?
    let requiredRunrate: Double?
    let lastFewOversRunrate: Double?
    let lastFewOversRuns: String?
    let lastFewOversWickets: String?
    let lastFewOversSixes: String?
    let lastFewOversFours: String?
}

// MARK: - Match

struct Match: Codable {
    let status: String?
    let statusText: String
    let teams: [TeamWrapper]
    let liveInning: Int
    let liveInningPredictions: LiveInningPredictions?

    let statusData: StatusData?
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
    
    let currentBattingTeamId: Int32?
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
    let overs: Double
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
    let overs: Double?
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
    let id: Int32          // ← add this
    let longName: String
    let abbreviation: String
}

struct LiveInningPredictions: Codable {
    let winProbability: Double
}


struct MatchScore {
    let team1: String
    let team1Score: String

    let team2: String
    let team2Score: String

    let status: String
    let equation: String
    let isMatchOver: Bool
    let liveInning: Int

    let currentRR: String
    let requiredRR: String

    let winProbability: String
    let winProbabilityT2: String
    let lastOver: [String]

    let batters: [Batter]
    let bowlers: [Bowler]
    
    let bowlerPlayerId: Int
    let batsmanPlayerId: Int
    let battingTeamId: Int
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


struct RecentBallCommentary: Codable {
    let ballComments: [BallComment]
}

struct BallComment: Codable {
    let overNumber: Int
    let ballNumber: Int

    let totalRuns: Int
    let isWicket: Bool

    let wides: Int
    let noballs: Int
}


func getLastNBalls(from comments: [BallComment], count: Int = 9) -> [String] {

    let sorted = comments.sorted {
        if $0.overNumber == $1.overNumber {
            return $0.ballNumber > $1.ballNumber
        }
        return $0.overNumber > $1.overNumber
    }

    let lastBalls = sorted.prefix(count).reversed()

    return lastBalls.map { ball in
        if ball.isWicket {
            return "W"
        } else if ball.wides > 0 {
            return "\(ball.wides)wd"
        } else if ball.noballs > 0 {
            return "\(ball.noballs)nb"
        } else if ball.totalRuns == 0 {
            return "."
        } else {
            return "\(ball.totalRuns)"
        }
    }
}



extension MatchResponse {

    func toMatchScore() -> MatchScore {

        let t1 = match.teams[0]
        let t2 = match.teams[1]

        let isMatchOver = match.status == "RESULT"

        // MARK: - Batters
        let batters: [Batter]
        
        let lastBalls = getLastNBalls(
            from: recentBallCommentary?.ballComments ?? []
        )

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
        } else if let livePerf = self.livePerformance, !livePerf.batsmen.isEmpty {  // self instead of match
            batters = livePerf.batsmen.prefix(2).map {
                Batter(
                    name: $0.player.longName,
                    runs: $0.runs,
                    balls: $0.balls,
                    fours: $0.fours,
                    sixes: $0.sixes,
                    strikeRate: (Double($0.runs) / Double(max($0.balls, 1))) * 100
                )
            }
        } else {
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
        } else if let livePerf = self.livePerformance {  // self instead of match
            bowlers = livePerf.bowlers.prefix(2).map {
                Bowler(
                    name: $0.player.longName,
                    overs: overs(from: $0.balls),
                    runs: $0.conceded,
                    wickets: $0.wickets,
                    economy: $0.economy
                )
            }
        } else {
            bowlers = []
        }

        // MARK: - Run Rate
        let liveData = match.statusData?.statusTextLangData
        let currentRR = self.supportInfo?.liveInfo?.currentRunRate
            ?? liveData?.currentRunRate
            ?? liveData?.crr
            ?? 0
        
        let battingTeamId = match.statusData?.statusTextLangData?.currentBattingTeamId
        
        let battingTeam = match.teams.first(where: { $0.team.id == battingTeamId })
        let bowlingTeam = match.teams.first(where: { $0.team.id != battingTeamId })

        let winProb = match.liveInningPredictions?.winProbability ?? 0
        
        let battingProb = Int(winProb)
        let bowlingProb = Int(100 - battingProb)

        let winProbability = "\(battingTeam?.team.abbreviation ?? "") \(battingProb)%"
        let winProbabilityT2 = "\(bowlingTeam?.team.abbreviation ?? "") \(bowlingProb)%"

        let requiredRR = self.supportInfo?.liveInfo?.requiredRunrate
            ?? liveData?.requiredRunrate
            ?? liveData?.rrr
            ?? 0

        let equation = isMatchOver || match.liveInning == 1
            ? ""
            : "Need \(liveData?.requiredRuns ?? 0) runs in \(liveData?.remainingBalls ?? 0) balls"
        
        let batsmanPlayerId = self.supportInfo?.liveSummary?.recentBalls.first?.batsmanPlayerId
        let bowlerPlayerId = self.supportInfo?.liveSummary?.recentBalls.first?.bowlerPlayerId
        
        return MatchScore(
            team1: t1.team.longName,
            team1Score: t1.score ?? "-",
            team2: t2.team.longName,
            team2Score: t2.score ?? "Yet to bat",
            status: match.statusText,
            equation: equation,
            isMatchOver: isMatchOver,
            liveInning: match.liveInning,
            currentRR: String(format: "%.2f", currentRR),
            requiredRR: String(format: "%.2f", requiredRR),
            winProbability: winProbability,
            winProbabilityT2: winProbabilityT2,
            lastOver: lastBalls,
            batters: batters,
            bowlers: bowlers,
            bowlerPlayerId: bowlerPlayerId ?? 0,
            batsmanPlayerId: batsmanPlayerId ?? 0,
            battingTeamId: battingTeamId ?? 0
        )
    }
}
