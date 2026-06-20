import SwiftUI
import Observation

/// Session state + backend calls that drive the screens. Injected into the
/// environment by `RootView` (live) and by the gallery (sample).
@MainActor
@Observable
final class CarlStore {
    var credits = 3
    var resumeText: String?
    var parsed: ParsedResume?
    var search: SearchResponse?
    var queue: [QueueItem] = []
    var dashboard: DashboardResponse?
    var busy = false

    var booted = false
    var connected = true
    var loadingQueue = false
    var loadingDashboard = false

    var prefs = JobPrefs(titles: ["Product Designer"], locationType: "remote",
                         location: nil, country: "us", payFloor: 120, workType: "full-time")
    /// Contact details employers will reach the user on (pre-filled from the résumé).
    var contact = Contact(name: "", email: "", phone: "")
    /// Standard screening answers Carl fills in on applications.
    var eligibility = Eligibility()

    private let api = CarlAPI.shared
    let storeKit = StoreService()
    static let sampleResume =
        "Senior Product Designer with 6 years of experience. Skills: Figma, " +
        "Design Systems, Prototyping, UX Research. Led design systems end-to-end."

    // MARK: Onboarding

    func boot() async {
        do {
            _ = try await api.authAnon()
            connected = true
        } catch {
            connected = false
            booted = true
            return
        }
        await refreshCredits()
        await storeKit.load()
        booted = true
    }

    func retry() async {
        booted = false
        await boot()
    }

    func savePreferences() async { try? await api.updatePrefs(prefs) }

    func parseResume() async {
        parsed = try? await api.parseResume(text: resumeText ?? Self.sampleResume)
        // Pre-fill contact from the résumé so the user just confirms it.
        if let c = parsed?.contact {
            if contact.name.isEmpty { contact.name = c.name }
            if contact.email.isEmpty { contact.email = c.email }
            if contact.phone.isEmpty { contact.phone = c.phone }
        }
    }

    /// Persist the contact details employers will use to reach the user.
    func saveContact() async { try? await api.updateContact(contact) }

    /// Persist the screening answers Carl uses on applications.
    func saveEligibility() async { try? await api.updateEligibility(eligibility) }

    /// Companies Carl will never apply to (e.g. the user's current employer).
    var blockedCompanies: [String] = []

    func block(_ company: String) async {
        if let r = try? await api.blockCompany(company) { blockedCompanies = r.blockedCompanies }
        await loadQueue()
    }

    func unblock(_ company: String) async {
        if let r = try? await api.blockCompany(company, remove: true) { blockedCompanies = r.blockedCompanies }
    }

    func loadBlocklist() async {
        if let r = try? await api.profile() { blockedCompanies = r.blockedCompanies ?? [] }
    }

    // MARK: Résumé builder (one-time $14.99 unlock)

    var hasResumeBuilder = false

    /// Buy the résumé-builder unlock via StoreKit (falls back to a direct grant
    /// in dev when no StoreKit product is configured). Returns success.
    func buyResumeBuilder() async -> Bool {
        if let product = storeKit.product(id: StoreService.resumeBuilderID) {
            guard let tx = await storeKit.purchase(product) else { return false }
            _ = try? await api.buyResumeBuilder(receipt: tx.jwsRepresentation)
        } else {
            _ = try? await api.buyResumeBuilder()
        }
        hasResumeBuilder = true
        Haptics.success()
        return true
    }

    /// Generate a résumé from the user's notes and use it as their résumé.
    func buildResume(_ input: ResumeBuildInput) async -> Bool {
        guard let text = try? await api.buildResume(input) else { return false }
        resumeText = text
        return true
    }

    func runSearch() async {
        search = try? await api.search(prefs: prefs)
    }

    /// Buy a pack via StoreKit, then grant credits on the backend. Falls back to
    /// a direct backend grant when no StoreKit product is available (dev without
    /// the .storekit config or before App Store Connect setup). Returns success.
    @discardableResult
    func buy(packId: String) async -> Bool {
        if let product = storeKit.product(id: "com.carlapp.credits.\(packId)") {
            guard let tx = await storeKit.purchase(product) else { return false }
            // Send the signed transaction (JWS) so the backend can verify it.
            _ = try? await api.purchase(packId: packId, receipt: tx.jwsRepresentation)
        } else {
            _ = try? await api.purchase(packId: packId)
        }
        await refreshCredits()
        Haptics.success()
        return true
    }

    // MARK: Main app

    func loadQueue() async {
        loadingQueue = true
        if let q = try? await api.queue() { queue = q.items; credits = q.credits }
        loadingQueue = false
    }

    /// Per-application edits to the cover note, keyed by matchId (applied on send).
    var draftEdits: [String: String] = [:]
    /// Match ids whose résumé is currently being tailored (for in-progress UI).
    var tailoring: Set<String> = []

    /// Tailor the résumé to a job (premium, +1 credit on submit).
    func tailorResume(_ matchId: String) async {
        tailoring.insert(matchId)
        try? await api.tailorResume(matchId: matchId)
        await loadQueue()
        tailoring.remove(matchId)
        Haptics.success()
    }

    func confirm(_ matchId: String) async {
        if let r = try? await api.confirm(matchId: matchId, coverNote: draftEdits[matchId]) {
            if let c = r.credits { credits = c }
            if r.submitted { Haptics.success() }
        }
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
        loadingDashboard = true
        dashboard = try? await api.dashboard()
        if let c = dashboard?.credits { credits = c }
        loadingDashboard = false
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
            appliedToday: 47, totalApplied: 218, autoApplied: 156, avgFit: 88, credits: 102,
            activity: [
                ActivityDTO(id: "1", type: "applied", dot: "royal", text: "Auto-applied to Senior Designer · Northwind", ts: "1h"),
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
                  letter: "V", avatarColor: "lever", tier: "B",
                  draft: Draft(coverNote: "Vela's robotics work is exciting…", answers: [])),
    ]
}
