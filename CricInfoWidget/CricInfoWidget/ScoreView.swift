import SwiftUI

struct ScoreView: View {
    @ObservedObject var viewModel: ScoreViewModel
    
    var body: some View {
        Group {
            if let score = viewModel.score {
                VStack(alignment: .leading, spacing: 10) {
                    
                    // 🏏 Teams
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
                    
                    // ✅ Match Status (always visible)
                    Text(score.status)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(score.isMatchOver ? .green : .primary)
                    
                    // 🟢 LIVE MATCH UI
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
                        
                        // 🔥 Last Over Balls
                        HStack(spacing: 6) {
                            ForEach(score.lastOver, id: \.self) { ball in
                                BallView(value: ball)
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
                    
                    // 🏏 BATTERS
                    Text("BATTERS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(score.batters, id: \.name) { batter in
                        HStack {
                            HStack(spacing: 2) {
                                Text(batter.name)
                                if(batter.id == score.batsmanPlayerId){
                                    Text("*").foregroundColor(.blue)
                                }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            
                            
                            Text("\(batter.runs)")
                            Text("\(batter.balls)")
                            Text("\(batter.fours)")
                            Text("\(batter.sixes)")
                            Text(String(format: "%.2f", batter.strikeRate))
                        }
                        .font(.caption2)
                    }
                    
                    Divider()
                    
                    // 🎯 BOWLERS
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
                .padding()
                .frame(width: 320)
                
            } else {
                Text("Loading...")
                    .padding()
                    .frame(width: 300)
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
            
            HStack(alignment: .center,spacing: 2) {
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
    }}

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
        case "4": return .green
        case "6": return .blue
        case "W": return .red
        case ".": return .gray.opacity(0.5)
        default: return .gray
        }
    }
}
