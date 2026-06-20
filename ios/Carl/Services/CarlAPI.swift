import Foundation

// MARK: - DTOs (mirror the backend JSON)

struct UserDTO: Codable { let id: String; let name: String; let email: String; let credits: Int }
struct AuthResponse: Codable { let token: String; let user: UserDTO }

/// The details an employer uses to reach the user — carried on every application.
struct Contact: Codable, Equatable { var name: String; var email: String; var phone: String }

/// Standard application screening answers Carl fills in on the user's behalf.
struct Eligibility: Codable, Equatable {
    var authorized: Bool = true
    var needsSponsorship: Bool = false
    var willingToRelocate: Bool = false
    var salaryExpectation: String = ""
    var noticePeriod: String = ""
    var linkedinUrl: String = ""
    var portfolioUrl: String = ""
    var gender: String = "decline"
    var race: String = "decline"
    var veteranStatus: String = "decline"
    var disabilityStatus: String = "decline"
}

struct ParsedResume: Codable {
    let targetRole: String
    let years: Int
    let seniority: String
    let skills: [String]
    let summary: String
    var contact: Contact? = nil
}

struct JobPrefs: Codable {
    var titles: [String]?
    var locationType: String?   // remote | hybrid | onsite | any
    var location: String?
    var country: String?        // us | ca | uk | au
    var payFloor: Int?
    var workType: String?       // full-time | part-time | contract
}

struct SourceCount: Codable, Identifiable { let name: String; let found: Int; var id: String { name } }

struct MatchDTO: Codable, Identifiable {
    let matchId: String
    let fit: Int
    let reasons: [String]
    let status: String
    let title: String
    let company: String
    let detail: String
    let location: String
    let pay: String
    let letter: String
    let avatarColor: String
    let tier: String
    let source: String
    var id: String { matchId }
}

struct SearchResponse: Codable {
    let count: Int
    let avgFit: Int
    let sources: [SourceCount]
    let topMatches: [MatchDTO]
}

struct QA: Codable { let question: String; let answer: String }
struct Draft: Codable { let coverNote: String; let answers: [QA] }

struct QueueItem: Codable, Identifiable {
    let matchId: String
    let applicationId: String
    let fit: Int
    let reasons: [String]
    let title: String
    let company: String
    let detail: String
    let letter: String
    let avatarColor: String
    let tier: String
    let draft: Draft
    var tailored: Bool? = nil
    var id: String { matchId }
}
struct QueueResponse: Codable { let credits: Int; let items: [QueueItem] }

struct ConfirmResponse: Codable { let submitted: Bool; let credits: Int?; let mode: String? }

struct ActivityDTO: Codable, Identifiable {
    let id: String; let type: String; let dot: String; let text: String; let ts: String
}
struct DashboardResponse: Codable {
    let appliedToday: Int
    let totalApplied: Int
    let autoApplied: Int
    let avgFit: Int
    let credits: Int
    let activity: [ActivityDTO]
}

struct Pack: Codable, Identifiable {
    let id: String; let name: String; let credits: Int
    let applications: Int; let bonus: Int?; let price: Int; let priceText: String
}
struct CreditsResponse: Codable { let balance: Int; let packs: [Pack] }
struct PurchaseResponse: Codable { let ok: Bool; let granted: Int?; let balance: Int? }
struct BlocklistResponse: Codable { let blockedCompanies: [String] }
struct ProfileResponse: Codable {
    let blockedCompanies: [String]?
    let contact: Contact?
    let resume: ParsedResume?
    let eligibility: Eligibility?
}
struct EntitlementResponse: Codable { let ok: Bool; let entitlements: [String]? }
struct ResumeBuildInput: Codable { var name: String; var role: String; var years: String; var skills: String; var experience: String }

// MARK: - API client

enum CarlAPIError: Error { case http(Int), decoding, noToken }

/// Talks to the Carl backend. Set `baseURL` to your server (defaults to the
/// local dev server). Holds the auth token for the session.
actor CarlAPI {
    static let shared = CarlAPI()

    /// For the simulator, `localhost` reaches your Mac's localhost. On a device,
    /// point this at your machine's LAN IP or deployed server.
    var baseURL = URL(string: "http://localhost:8787")!
    private var token: String?

    func setBaseURL(_ url: URL) { baseURL = url }

    // Flow ---------------------------------------------------------------

    @discardableResult
    func authAnon() async throws -> AuthResponse {
        let res: AuthResponse = try await request("POST", "/v1/auth/anon", auth: false)
        token = res.token
        return res
    }

    func updatePrefs(_ prefs: JobPrefs) async throws {
        struct Body: Codable { let prefs: JobPrefs }
        let _: EmptyAck = try await request("PUT", "/v1/profile", body: Body(prefs: prefs))
    }

    /// Save the contact details employers will use to reach the user.
    func updateContact(_ contact: Contact) async throws {
        struct Body: Codable { let contact: Contact }
        let _: EmptyAck = try await request("PUT", "/v1/profile", body: Body(contact: contact))
    }

    /// Save the standard screening answers Carl uses to fill out applications.
    func updateEligibility(_ eligibility: Eligibility) async throws {
        struct Body: Codable { let eligibility: Eligibility }
        let _: EmptyAck = try await request("PUT", "/v1/profile", body: Body(eligibility: eligibility))
    }

    /// Block (or unblock) a company so Carl never applies there.
    func blockCompany(_ company: String, remove: Bool = false) async throws -> BlocklistResponse {
        struct Body: Codable { let company: String; let remove: Bool }
        return try await request("POST", "/v1/blocklist", body: Body(company: company, remove: remove))
    }

    /// Purchase the one-time résumé-builder unlock ($14.99).
    func buyResumeBuilder(receipt: String? = nil) async throws -> EntitlementResponse {
        struct Body: Codable { let productId: String; let receipt: String? }
        return try await request("POST", "/v1/entitlements/purchase",
                                 body: Body(productId: "com.carlapp.resumebuilder", receipt: receipt))
    }

    /// Generate a full résumé from the user's notes (requires the unlock).
    func buildResume(_ input: ResumeBuildInput) async throws -> String {
        struct Body: Codable { let input: ResumeBuildInput }
        struct R: Codable { let resume: String }
        let r: R = try await request("POST", "/v1/resume/build", body: Body(input: input))
        return r.resume
    }

    func parseResume(text: String) async throws -> ParsedResume {
        struct Body: Codable { let text: String }
        struct Wrap: Codable { let parsed: ParsedResume }
        let w: Wrap = try await request("POST", "/v1/resume", body: Body(text: text))
        return w.parsed
    }

    func profile() async throws -> ProfileResponse {
        try await request("GET", "/v1/profile")
    }

    func search(prefs: JobPrefs? = nil) async throws -> SearchResponse {
        struct Body: Codable { let prefs: JobPrefs? }
        return try await request("POST", "/v1/search", body: Body(prefs: prefs))
    }

    func queue() async throws -> QueueResponse {
        try await request("GET", "/v1/queue")
    }

    /// Generate a résumé tailored to this job (charged +1 credit on submit).
    func tailorResume(matchId: String) async throws {
        struct R: Codable { let tailored: Bool }
        let _: R = try await request("POST", "/v1/applications/\(matchId)/tailor-resume")
    }

    func confirm(matchId: String, coverNote: String? = nil) async throws -> ConfirmResponse {
        struct Body: Codable { let coverNote: String? }
        return try await request("POST", "/v1/applications/\(matchId)/confirm", body: Body(coverNote: coverNote))
    }

    func confirmAll() async throws -> ConfirmResponse {
        try await request("POST", "/v1/applications/confirm-all")
    }

    func dashboard() async throws -> DashboardResponse {
        try await request("GET", "/v1/dashboard")
    }

    func credits() async throws -> CreditsResponse {
        try await request("GET", "/v1/credits")
    }

    func purchase(packId: String, receipt: String? = nil) async throws -> PurchaseResponse {
        struct Body: Codable { let packId: String; let receipt: String? }
        return try await request("POST", "/v1/credits/purchase", body: Body(packId: packId, receipt: receipt))
    }

    // Transport ----------------------------------------------------------

    private struct EmptyAck: Codable {}

    private func request<T: Decodable>(_ method: String, _ path: String, auth: Bool = true) async throws -> T {
        try await request(method, path, body: Optional<EmptyAck>.none, auth: auth)
    }

    private func request<T: Decodable, B: Encodable>(_ method: String, _ path: String, body: B?, auth: Bool = true) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if auth {
            guard let token else { throw CarlAPIError.noToken }
            req.setValue(token, forHTTPHeaderField: "x-carl-token")
        }
        if let body { req.httpBody = try JSONEncoder().encode(body) }

        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else { throw CarlAPIError.http(code) }
        if T.self == EmptyAck.self { return EmptyAck() as! T }
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw CarlAPIError.decoding }
    }
}
