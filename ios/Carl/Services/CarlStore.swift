import SwiftUI
import Observation

/// Session state + backend calls that drive the screens. Injected into the
/// environment by `RootView` (live) and by the gallery (sample).
@MainActor
@Observable
final class CarlStore {
    var credits = 3
    var parsed: ParsedResume?
    var search: SearchResponse?
    var queue: [QueueItem] = []
    var dashboard: DashboardResponse?
    var busy = false

    var prefs = JobPrefs(titles: ["Product Designer"], locationType: "remote",
                         location: nil, country: "us", payFloor: 120, workType: "full-time")

    private let api = CarlAPI.shared
    static let sampleResume =
        "Senior Product Designer with 6 years of experience. Skills: Figma, " +
        "Design Systems, Prototyping, UX Research. Led design systems end-to-end."

    // MARK: Onboarding

    func boot() async {
        _ = try? await api.authAnon()
        await refreshCredits()
    }

    func savePreferences() async { try? await api.updatePrefs(prefs) }

    func parseResume() async {
        parsed = try? await api.parseResume(text: Self.sampleResume)
    }

    func runSearch() async {
        search = try? await api.search(prefs: prefs)
    }

    func purchasePopular() async {
        _ = try? await api.purchase(packId: "popular")
        await refreshCredits()
    }

    // MARK: Main app

    func loadQueue() async {
        if let q = try? await api.queue() { queue = q.items; credits = q.credits }
    }

    func confirm(_ matchId: String) async {
        if let r = try? await api.confirm(matchId: matchId), let c = r.credits { credits = c }
        await loadQueue()
        await loadDashboard()
    }

    func confirmAll() async {
        busy = true
        _ = try? await api.confirmAll()
        await loadQueue()
        await loadDashboard()
        busy = false
    }

    func loadDashboard() async {
        dashboard = try? await api.dashboard()
        if let c = dashboard?.credits { credits = c }
    }

    func refreshCredits() async {
        if let c = try? await api.credits() { credits = c.balance }
    }

    // MARK: Sample (gallery / previews)

    static let sample: CarlStore = {
        let s = CarlStore()
        s.credits = 102
        s.parsed = ParsedResume(targetRole: "Senior Product Designer", years: 6,
                                seniority: "Senior",
                                skills: ["Figma", "Design Systems", "Prototyping", "UX Research"],
                                summary: "")
        s.search = SearchResponse(
            count: 312, avgFit: 88,
            sources: [SourceCount(name: "LinkedIn Jobs", found: 142),
                      SourceCount(name: "Greenhouse", found: 86),
                      SourceCount(name: "Lever", found: 54),
                      SourceCount(name: "Ashby", found: 30)],
            topMatches: sampleMatches)
        s.queue = sampleQueue
        s.dashboard = DashboardResponse(
            appliedToday: 47, totalApplied: 218, responses: 19, interviews: 4, credits: 102,
            activity: [
                ActivityDTO(id: "1", type: "responded", dot: "green", text: "Acme replied to your application", ts: "1h"),
                ActivityDTO(id: "2", type: "applied", dot: "royal", text: "Applied to Senior Designer · Acme", ts: "2h"),
                ActivityDTO(id: "3", type: "applied", dot: "royal", text: "Applied to Product Designer · Lumen", ts: "2h"),
            ])
        return s
    }()

    static let sampleMatches: [MatchDTO] = [
        MatchDTO(matchId: "m1", fit: 96, reasons: ["role matches", "remote"], status: "suggested",
                 title: "Senior Product Designer", company: "Northwind", detail: "Remote · $145–170k",
                 location: "Remote", pay: "$145–170k", letter: "N", avatarColor: "navy", tier: "A", source: "Greenhouse"),
        MatchDTO(matchId: "m2", fit: 94, reasons: ["pay in range"], status: "suggested",
                 title: "Product Designer", company: "Lumen Health", detail: "SF Hybrid · $130–155k",
                 location: "SF Hybrid", pay: "$130–155k", letter: "L", avatarColor: "greenhouse", tier: "A", source: "Greenhouse"),
        MatchDTO(matchId: "m3", fit: 92, reasons: ["strong overlap"], status: "suggested",
                 title: "Staff Product Designer", company: "Vela Robotics", detail: "Austin · $170–200k",
                 location: "Austin", pay: "$170–200k", letter: "V", avatarColor: "lever", tier: "A", source: "Lever"),
    ]

    static let sampleQueue: [QueueItem] = [
        QueueItem(matchId: "m1", applicationId: "a1", fit: 96, reasons: ["skills + 6 yrs match, pay in range, remote"],
                  title: "Senior Product Designer", company: "Northwind", detail: "Remote · $145–170k",
                  letter: "N", avatarColor: "navy", tier: "A",
                  draft: Draft(coverNote: "Northwind's systems-led design culture is exactly where I do my best work. Over 6 years I've shipped design systems that…",
                               answers: [QA(question: "Why do you want this role?", answer: "I want to own a design system end-to-end with a team that values craft…")])),
        QueueItem(matchId: "m2", applicationId: "a2", fit: 94, reasons: ["pay in range"],
                  title: "Product Designer", company: "Lumen Health", detail: "SF Hybrid · $130–155k",
                  letter: "L", avatarColor: "greenhouse", tier: "A",
                  draft: Draft(coverNote: "Lumen's mission resonates with me…", answers: [])),
        QueueItem(matchId: "m3", applicationId: "a3", fit: 92, reasons: ["strong overlap"],
                  title: "Staff Product Designer", company: "Vela Robotics", detail: "Austin · $170–200k",
                  letter: "V", avatarColor: "lever", tier: "A",
                  draft: Draft(coverNote: "Vela's robotics work is exciting…", answers: [])),
    ]
}
