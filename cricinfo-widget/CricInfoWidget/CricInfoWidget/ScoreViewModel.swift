import Foundation
import Combine

@MainActor
class ScoreViewModel: ObservableObject {
    @Published var score: MatchScore?
    @Published var matches: [MatchListItem] = []
    @Published var selectedMatchId: String?
    @Published var isLoadingMatches = true
    @Published var menuBarTitle = "cric_info"

    private var pollingTask: Task<Void, Never>?
    private let selectedMatchKey = "selected_match_id"
    private let notifications: NotificationSending
    private let eventDetector = MatchEventDetector()

    init(notifications: NotificationSending = NotificationService()) {
        self.notifications = notifications
        Task {
            await notifications.requestAuthorizationIfNeeded()
            await loadMatchesAndSelectDefault()
        }
        startPolling()
    }

    func loadMatchesAndSelectDefault() async {
        isLoadingMatches = true
        let fetched = await APIService.fetchMatches()
            .sorted {
                if $0.isLive != $1.isLive {
                    return $0.isLive && !$1.isLive
                }
                return $0.displayTitle < $1.displayTitle
            }

        matches = fetched
        isLoadingMatches = false

        guard !fetched.isEmpty else {
            selectedMatchId = nil
            score = nil
            updateMenuBarTitle()
            return
        }

        let stored = UserDefaults.standard.string(forKey: selectedMatchKey)
        let initialId: String
        if let stored, fetched.contains(where: { $0.id == stored }) {
            initialId = stored
        } else if let live = fetched.first(where: { $0.isLive }) {
            initialId = live.id
        } else {
            initialId = fetched[0].id
        }

        await selectMatch(initialId)
    }

    func selectMatch(_ matchId: String) async {
        let didChangeMatch = selectedMatchId != matchId
        selectedMatchId = matchId
        UserDefaults.standard.set(matchId, forKey: selectedMatchKey)
        _ = await APIService.setPreferredMatch(matchId: matchId)

        if didChangeMatch {
            eventDetector.reset()
        }

        if let result = await APIService.fetchMatch(matchId: matchId) {
            handleIncomingScore(result)
        }
        updateMenuBarTitle()
    }

    func startPolling() {
        pollingTask = Task {
            while !Task.isCancelled {
                guard let matchId = selectedMatchId else {
                    try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                    continue
                }

                if let result = await APIService.fetchMatch(matchId: matchId) {
                    handleIncomingScore(result)
                }
                updateMenuBarTitle()

                try? await Task.sleep(nanoseconds: 25 * 1_000_000_000)
            }
        }
    }

    private func handleIncomingScore(_ latest: MatchScore) {
        let events = eventDetector.detectEvents(score: latest)
        score = latest

        for event in events {
            notifications.send(title: event.title, body: event.body, id: event.id)
        }
    }

    private func updateMenuBarTitle() {
        guard selectedMatchId != nil, let score else {
            menuBarTitle = "cric_info"
            return
        }

        let isTeam1Batting = score.currentBattingTeamId == score.team1Id
        let short = isTeam1Batting ? score.team1Abbreviation : score.team2Abbreviation
        let battingScore = isTeam1Batting ? score.team1Score : score.team2Score
        menuBarTitle = "\(short) \(battingScore)"
    }

    deinit {
        pollingTask?.cancel()
    }
}
