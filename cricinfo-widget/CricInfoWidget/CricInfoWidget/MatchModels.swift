
import Foundation

struct MatchListItem: Codable, Identifiable, Hashable {
    let id: String
    let title: String?
    let team1: String?
    let team2: String?
    let text: String?
    let isLive: Bool

    var displayTitle: String {
        if let team1, let team2 {
            return "\(team1) vs \(team2)"
        }
        return title ?? "Match \(id)"
    }

    var subtitle: String {
        text ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case id, title, team1, team2, text, isLive
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let stringId = try? container.decode(String.self, forKey: .id) {
            id = stringId
        } else if let intId = try? container.decode(Int.self, forKey: .id) {
            id = String(intId)
        } else {
            id = UUID().uuidString
        }

        title = try? container.decode(String.self, forKey: .title)
        team1 = try? container.decode(String.self, forKey: .team1)
        team2 = try? container.decode(String.self, forKey: .team2)
        text = try? container.decode(String.self, forKey: .text)
        isLive = (try? container.decode(Bool.self, forKey: .isLive)) ?? false
    }
}

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
    let liveOvers: Double
    let statusData: StatusData?
    let isSuperOver: Bool

    enum CodingKeys: String, CodingKey {
        case status
        case statusText
        case teams
        case liveInning
        case liveInningPredictions
        case liveOvers
        case statusData
        case isSuperOver
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        statusText = try container.decode(String.self, forKey: .statusText)
        teams = try container.decode([TeamWrapper].self, forKey: .teams)
        liveInning = try container.decode(Int.self, forKey: .liveInning)
        liveInningPredictions = try container.decodeIfPresent(
            LiveInningPredictions.self,
            forKey: .liveInningPredictions
        )
        liveOvers = try container.decode(Double.self, forKey: .liveOvers)
        statusData = try container.decodeIfPresent(StatusData.self, forKey: .statusData)
        isSuperOver = try container.decodeIfPresent(Bool.self, forKey: .isSuperOver) ?? false
    }
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
    
    let currentBattingTeamId: Int?
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
    let id: Int32
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
    let team1Abbreviation: String
    let team1Score: String

    let team2: String
    let team2Abbreviation: String
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
    let currentBattingTeamId: Int32
    let liveOvers: Double
    
    let team1Id: Int32
    let team2Id: Int32
    let isSuperOver: Bool
    let recentBalls: [Ball]
}

struct Batter {
    let id: Int32
    let name: String
    let runs: Int
    let balls: Int
    let fours: Int
    let sixes: Int
    let strikeRate: Double
}

struct Bowler {
    let id: Int32
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


func getLastNBalls(from comments: [BallComment], count: Int = 10) -> [String] {

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

        if isMatchOver, let perf = self.bestPerformance {
            batters = perf.batsmen.prefix(2).map {
                Batter(
                    id: $0.player.id,
                    name: $0.player.longName,
                    runs: $0.runs,
                    balls: $0.balls,
                    fours: $0.fours ?? 0,
                    sixes: $0.sixes ?? 0,
                    strikeRate: $0.strikerate ?? 0
                )
            }
        } else if let livePerf = self.livePerformance, !livePerf.batsmen.isEmpty {
            batters = livePerf.batsmen.prefix(2).map {
                Batter(
                    id: $0.player.id,
                    name: $0.player.longName,
                    runs: $0.runs,
                    balls: $0.balls,
                    fours: $0.fours,
                    sixes: $0.sixes,
                    strikeRate: $0.strikerate   // ✅ use API value
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

        if isMatchOver, let perf = self.bestPerformance {
            bowlers = perf.bowlers.prefix(2).map {
                Bowler(
                    id: $0.player.id,
                    name: $0.player.longName,
                    overs: overs(from: $0.balls ?? 0),
                    runs: $0.conceded ?? 0,
                    wickets: $0.wickets ?? 0,
                    economy: $0.economy ?? 0
                )
            }
        } else if let livePerf = self.livePerformance {
            bowlers = livePerf.bowlers.prefix(2).map {
                Bowler(
                    id: $0.player.id,
                    name: $0.player.longName,
                    overs: overs(from: $0.balls),
                    runs: $0.conceded,
                    wickets: $0.wickets,
                    economy: $0.economy
                )
            }
        }else {
            bowlers = []
        }

        // MARK: - Run Rate
        let liveData = match.statusData?.statusTextLangData
        let currentRR = self.supportInfo?.liveInfo?.currentRunRate
            ?? liveData?.currentRunRate
            ?? liveData?.crr
            ?? 0
        
        let battingTeamId: Int32? =
            liveData?.currentBattingTeamId.map { Int32($0) }
            ?? match.teams.first?.team.id
        
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
            team1Abbreviation: t1.team.abbreviation,
            team1Score: t1.score ?? "-",
            team2: t2.team.longName,
            team2Abbreviation: t2.team.abbreviation,
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
            currentBattingTeamId: battingTeamId ?? 0,
            liveOvers: match.liveOvers,
            team1Id: t1.team.id,
            team2Id: t2.team.id,
            isSuperOver: match.isSuperOver,
            recentBalls: supportInfo?.liveSummary?.recentBalls ?? []
            
        )
    }
}
