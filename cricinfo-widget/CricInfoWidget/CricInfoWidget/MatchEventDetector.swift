import Foundation

struct MatchNotificationEvent {
    let id: String
    let title: String
    let body: String
}

final class MatchEventDetector {
    private var emittedKeys = Set<String>()
    private var currentInning: Int?
    private var lastRunsByPlayer: [Int32: Int] = [:]
    private var lastStrikeRateByPlayer: [Int32: Double] = [:]
    private var wasSuperOver = false
    private var wasMatchOver = false

    func reset() {
        emittedKeys.removeAll()
        currentInning = nil
        lastRunsByPlayer.removeAll()
        lastStrikeRateByPlayer.removeAll()
        wasSuperOver = false
        wasMatchOver = false
    }

    func detectEvents(score: MatchScore) -> [MatchNotificationEvent] {
        rolloverIfInningChanged(score.liveInning)

        var events: [MatchNotificationEvent] = []

        for batter in score.batters {
            let previousRuns = lastRunsByPlayer[batter.id]
            if didCross(previous: previousRuns, current: batter.runs, threshold: 50) {
                maybeAppend(
                    &events,
                    key: "fifty:\(score.liveInning):\(batter.id)",
                    title: "Fifty up",
                    body: "\(batter.name) brings up 50"
                )
            }

            if didCross(previous: previousRuns, current: batter.runs, threshold: 100) {
                maybeAppend(
                    &events,
                    key: "hundred:\(score.liveInning):\(batter.id)",
                    title: "Century",
                    body: "\(batter.name) reaches 100"
                )
            }

            let previousStrikeRate = lastStrikeRateByPlayer[batter.id]
            if didCrossAbove(previous: previousStrikeRate, current: batter.strikeRate, threshold: 200) {
                maybeAppend(
                    &events,
                    key: "sr200:\(score.liveInning):\(batter.id)",
                    title: "Strike Rate Surge",
                    body: "\(batter.name) is striking above 200"
                )
            }

            lastRunsByPlayer[batter.id] = batter.runs
            lastStrikeRateByPlayer[batter.id] = batter.strikeRate
        }

        if score.isSuperOver && !wasSuperOver {
            maybeAppend(
                &events,
                key: "superover:\(score.liveInning)",
                title: "Super Over",
                body: "Super over has started"
            )
        }

        if score.isMatchOver && !wasMatchOver {
            maybeAppend(
                &events,
                key: "matchover",
                title: "Match Over",
                body: score.status
            )
        }

        appendTenRunOverEvents(score: score, events: &events)
        wasSuperOver = score.isSuperOver
        wasMatchOver = score.isMatchOver

        return events
    }

    private func rolloverIfInningChanged(_ liveInning: Int) {
        guard let currentInning else {
            currentInning = liveInning
            return
        }

        guard currentInning != liveInning else {
            return
        }

        self.currentInning = liveInning

        // New innings: clear stale dedupe keys and baseline values.
        emittedKeys.removeAll()
        lastRunsByPlayer.removeAll()
        lastStrikeRateByPlayer.removeAll()
        wasSuperOver = false
        wasMatchOver = false
    }

    private func maybeAppend(
        _ events: inout [MatchNotificationEvent],
        key: String,
        title: String,
        body: String
    ) {
        guard !emittedKeys.contains(key) else {
            return
        }

        emittedKeys.insert(key)
        events.append(MatchNotificationEvent(id: key, title: title, body: body))
    }

    private func didCross(previous: Int?, current: Int, threshold: Int) -> Bool {
        guard let previous else {
            return false
        }

        return previous < threshold && current >= threshold
    }

    private func didCrossAbove(previous: Double?, current: Double, threshold: Double) -> Bool {
        guard let previous else {
            return false
        }

        return previous <= threshold && current > threshold
    }

    private func appendTenRunOverEvents(score: MatchScore, events: inout [MatchNotificationEvent]) {
        let completedOvers = completedOverRuns(from: score.recentBalls)
        let battingAbbreviation = score.currentBattingTeamId == score.team1Id
            ? score.team1Abbreviation
            : score.team2Abbreviation

        for over in completedOvers where over.runs >= 20 {
            maybeAppend(
                &events,
                key: "team20over:\(score.liveInning):\(over.number)",
                title: "20+ Run Over",
                body: "\(battingAbbreviation) scored \(over.runs) in over \(over.number)"
            )
        }
    }

    private func completedOverRuns(from balls: [Ball]) -> [(number: Int, runs: Int)] {
        guard !balls.isEmpty else {
            return []
        }

        var byOver: [Int: [Ball]] = [:]
        for ball in balls {
            byOver[ball.overNumber, default: []].append(ball)
        }

        return byOver.compactMap { overNumber, overBalls in
            let legalBallMax = overBalls.map(\.ballNumber).max() ?? 0
            guard legalBallMax >= 6 else {
                return nil
            }

            let runs = overBalls.reduce(0) { partial, ball in
                partial + ball.totalRuns
            }

            return (number: overNumber, runs: runs)
        }
    }
}
