import SwiftUI
import SwiftUIPagedScrolling

/// An extracted view for individual game cards, featuring an isolated horizontal 
/// scrolling area to demonstrate nested scroll view control and gesture recognition.
struct MLBGameCardView: View {
    let game: MLBGame
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(game.status.detailedState)
                    .font(.caption.bold())
                    .foregroundColor(game.status.abstractGameState == "Live" ? .red : .secondary)
                Spacer()
                Text(game.venue.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Divider()
            teamRow(teamStatus: game.teams.away)
            teamRow(teamStatus: game.teams.home)
            
            if game.status.abstractGameState == "Final" {
                if let decisions = game.liveDetail?.liveData.decisions {
                    Divider()
                    decisionsRow(decisions: decisions)
                }
            } else if let linescore = game.liveDetail?.liveData.linescore {
                Divider()
                liveDetailRow(detail: linescore)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Horizontal scrolling area to show off scroll control
            VStack(alignment: .leading, spacing: 6) {
                Text("Match Highlights")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Mocking some horizontal items for demonstration
                        ForEach(1...8, id: \.self) { item in
                            VStack(spacing: 4) {
                                Image(systemName: "sportscourt")
                                    .font(.title2)
                                    .foregroundColor(.blue.opacity(0.8))
                                Text("Play \(item)")
                                    .font(.caption2)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color(UIColor.quaternarySystemFill))
                            .cornerRadius(8)
                        }
                    }
                }
                .ignorePagerGesture()
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func liveDetailRow(detail: MLBLinescore) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                if let inning = detail.currentInning, let state = detail.inningState {
                    Text("\(state) \(inning)")
                        .font(.caption.bold())
                }
                if let balls = detail.balls, let strikes = detail.strikes {
                    Text("\(balls) - \(strikes)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if let outs = detail.outs {
                    HStack(spacing: 6) {
                        Text("\(outs) Outs")
                            .font(.caption2)
                        outsIndicator(outs: outs)
                    }
                }
            }
            
            Spacer()
            
            basesDiamond(offense: detail.offense)
                .padding(.horizontal, 8)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let pitcher = detail.defense?.pitcher?.fullName {
                    Text("P: \(pitcher)")
                        .font(.caption)
                }
                if let batter = detail.offense?.batter?.fullName {
                    Text("B: \(batter)")
                        .font(.caption)
                }
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func basesDiamond(offense: MLBTeamStats?) -> some View {
        let firstOccupied = offense?.first != nil
        let secondOccupied = offense?.second != nil
        let thirdOccupied = offense?.third != nil
        
        VStack(spacing: 4) {
            baseDiamond(occupied: secondOccupied)
            HStack(spacing: 16) {
                baseDiamond(occupied: thirdOccupied)
                baseDiamond(occupied: firstOccupied)
            }
        }
    }
    
    @ViewBuilder
    private func baseDiamond(occupied: Bool) -> some View {
        Rectangle()
            .fill(occupied ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(45))
    }
    
    @ViewBuilder
    private func outsIndicator(outs: Int) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(i < outs ? Color.red : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }

    @ViewBuilder
    private func decisionsRow(decisions: MLBDecisions) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let winner = decisions.winner?.fullName {
                    Text("W: \(winner)")
                        .font(.caption)
                }
                if let loser = decisions.loser?.fullName {
                    Text("L: \(loser)")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let save = decisions.save?.fullName {
                    Text("S: \(save)")
                        .font(.caption)
                }
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func teamRow(teamStatus: MLBTeamStatus) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: teamStatus.team.logoURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Circle()
                    .fill(Color.secondary.opacity(0.2))
            }
            .frame(width: 30, height: 30)

            Text(teamStatus.team.name)
                .font(.headline)
                .fontWeight(teamStatus.isWinner == true ? .bold : .regular)
            Spacer()
            if let score = teamStatus.score {
                Text("\(score)")
                    .font(.title3)
                    .fontWeight(teamStatus.isWinner == true ? .bold : .regular)
            } else {
                Text("-")
                    .foregroundColor(.secondary)
            }
        }
    }
}
