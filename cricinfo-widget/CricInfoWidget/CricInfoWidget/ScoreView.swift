import SwiftUI

struct ScoreView: View {
    @ObservedObject var viewModel: ScoreViewModel

    var body: some View {
        VStack(alignment: .leading) {
            matchSelector

            if let score = viewModel.score {
                scoreContent(score)
            } else if viewModel.selectedMatchId != nil {
                Text("Waiting for score...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if !viewModel.isLoadingMatches {
                Text("No matches available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Loading matches...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 360)
    }

    private var matchSelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !viewModel.matches.isEmpty {
                Text("Select Match")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if viewModel.isLoadingMatches {
                ProgressView()
                    .controlSize(.small)
            } else if viewModel.matches.isEmpty {
                
            } else {
                Picker(
                    "Match",
                    selection: Binding(
                        get: { viewModel.selectedMatchId ?? viewModel.matches.first?.id ?? "" },
                        set: { nextId in
                            Task { await viewModel.selectMatch(nextId) }
                        }
                    )
                ) {
                    ForEach(viewModel.matches) { match in
                        Text(matchLabel(match))
                            .tag(match.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
        }
    }

    private func matchLabel(_ match: MatchListItem) -> String {
        let livePrefix = match.isLive ? "LIVE • " : ""
        return "\(livePrefix)\(match.displayTitle)"
    }

    @ViewBuilder
    private func scoreContent(_ score: MatchScore) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(spacing: 4) {
                teamRow(
                    name: score.team1,
                    score: score.team1Score,
                    isBatting: score.currentBattingTeamId == score.team1Id,
                    liveOvers: score.liveOvers
                )

                teamRow(
                    name: score.team2,
                    score: score.team2Score,
                    isBatting: score.currentBattingTeamId == score.team2Id,
                    liveOvers: score.liveOvers
                )
            }

            Text(score.status)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(score.isMatchOver ? .green : .primary)

            if !score.isMatchOver {
                if score.liveInning == 2 {
                    Text("CRR: \(score.currentRR) • RRR: \(score.requiredRR)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if score.liveInning == 1 {
                    Text("CRR: \(score.currentRR)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("Win Probability: \(score.winProbability) - \(score.winProbabilityT2)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                let tokens = ballTokens(from: score)
                HStack(spacing: 6) {
                    ForEach(Array(tokens.enumerated()), id: \.offset) { index, token in
                        if shouldShowCurrentOverSeparator(at: index, tokens: tokens) {
                            OverSeparatorView()
                        }

                        BallView(value: token.value)
                    }
                }
            }

            if score.isMatchOver {
                Divider()
                Text("Top Performers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            Text("BATTERS")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(score.batters, id: \.name) { batter in
                HStack {
                    HStack(spacing: 2) {
                        Text(batter.name)
                        if batter.id == score.batsmanPlayerId {
                            Text("*").foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(batter.runs)")
                    Text("\(batter.balls)")
                    Text("\(batter.fours)")
                    Text("\(batter.sixes)")
                    Text(String(format: "%.2f", batter.strikeRate))
                }
                .font(.caption2)
            }

            Divider()

            Text("BOWLERS")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(score.bowlers, id: \.name) { bowler in
                HStack {
                    HStack(spacing: 2) {
                        Text(bowler.name)

                        if bowler.id == score.bowlerPlayerId {
                            Text("*")
                                .foregroundColor(.blue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(String(format: "%.1f", bowler.overs))
                    Text("\(bowler.runs)")
                    Text("\(bowler.wickets)")
                    Text(String(format: "%.2f", bowler.economy))
                }
                .font(.caption2)
            }
        }
    }

    private func teamRow(
        name: String,
        score: String,
        isBatting: Bool,
        liveOvers: Double
    ) -> some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 2) {
                Text(name)
                    .font(.headline)

                if isBatting {
                    Text("(\(formatOvers(liveOvers)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()

            Text(score)
                .bold()
        }
    }

    private func ballTokens(from score: MatchScore) -> [BallToken] {
        let sorted = score.recentBalls.sorted {
            if $0.overNumber == $1.overNumber {
                return $0.ballNumber > $1.ballNumber
            }
            return $0.overNumber > $1.overNumber
        }

        let visible = Array(sorted.prefix(10).reversed())
        let currentOver = visible.map(\.overNumber).max() ?? -1

        return visible.map { ball in
            BallToken(
                value: formatBall(ball),
                isCurrentOver: ball.overNumber == currentOver
            )
        }
    }

    private func shouldShowCurrentOverSeparator(at index: Int, tokens: [BallToken]) -> Bool {
        guard index > 0 else {
            return false
        }

        return !tokens[index - 1].isCurrentOver && tokens[index].isCurrentOver
    }

    private func formatBall(_ ball: Ball) -> String {
        if ball.isWicket {
            return "W"
        }
        if ball.wides > 0 {
            return "\(ball.wides)wd"
        }
        if ball.noballs > 0 {
            return "\(ball.noballs)nb"
        }
        if ball.totalRuns == 0 {
            return "."
        }

        return "\(ball.totalRuns)"
    }
}

func formatOvers(_ overs: Double) -> String {
    let o = Int(overs)
    let balls = Int((overs - Double(o)) * 10)
    return "\(o).\(balls)"
}

struct BallView: View {
    let value: String

    var body: some View {
        Text(value)
            .font(.caption)
            .frame(width: 26, height: 26)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(6)
    }

    var backgroundColor: Color {
        switch value {
        case "4": return .blue
        case "6": return .green
        case "W": return .red
        case ".": return .gray.opacity(0.5)
        default: return .gray
        }
    }
}

private struct BallToken {
    let value: String
    let isCurrentOver: Bool
}

private struct OverSeparatorView: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.6))
            .frame(width: 1, height: 24)
            .padding(.horizontal, 2)
    }
}
