import StoreKit

/// StoreKit 2 wrapper for the credit packs (consumable IAP).
/// Product IDs follow `com.carlapp.credits.<packId>` so they map 1:1 to the
/// backend pack ids (starter / popular / pro).
@MainActor
@Observable
final class StoreService {
    static let resumeBuilderID = "com.carlapp.resumebuilder"
    static let ids = [
        "com.carlapp.credits.starter",
        "com.carlapp.credits.popular",
        "com.carlapp.credits.pro",
        "com.carlapp.resumebuilder",
    ]

    var products: [Product] = []
    var purchasing = false

    func load() async {
        products = (try? await Product.products(for: Self.ids)) ?? []
    }

    func product(id: String) -> Product? { products.first { $0.id == id } }

    /// Runs the purchase sheet. Returns the signed transaction JWS on success
    /// (the JWS lives on the `VerificationResult`, not the `Transaction`).
    func purchase(_ product: Product) async -> String? {
        purchasing = true
        defer { purchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    await tx.finish()
                    return verification.jwsRepresentation
                }
                return nil
            case .userCancelled, .pending:
                return nil
            @unknown default:
                return nil
            }
        } catch {
            return nil
        }
    }
}
