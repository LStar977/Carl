import SwiftUI

/// A matched job, as shown across the reveal, queue, dashboard and detail screens.
struct JobMatch: Identifiable {
    let id = UUID()
    var letter: String
    var avatarColor: Color
    var title: String
    var company: String
    var detail: String      // e.g. "Remote · $145–170k"
    var fit: Int            // percent

    var subtitle: String { "\(company) · \(detail)" }
}

enum SampleData {
    static let topMatches: [JobMatch] = [
        JobMatch(letter: "N", avatarColor: CarlColor.navy,
                 title: "Senior Product Designer", company: "Northwind",
                 detail: "Remote · $145–170k", fit: 96),
        JobMatch(letter: "L", avatarColor: CarlColor.greenhouse,
                 title: "Product Designer", company: "Lumen Health",
                 detail: "SF Hybrid · $130–155k", fit: 94),
        JobMatch(letter: "V", avatarColor: CarlColor.lever,
                 title: "Staff Product Designer", company: "Vela Robotics",
                 detail: "Austin · $170–200k", fit: 92)
    ]

    /// (name, packCount, applications, price, perEach, bonus)
    struct CreditPack: Identifiable {
        let id = UUID()
        var name: String
        var credits: Int
        var applications: Int
        var price: String
        var perEach: String
        var bonus: Int
    }

    static let packs: [CreditPack] = [
        CreditPack(name: "Starter", credits: 25, applications: 25, price: "$19", perEach: "$0.76 each", bonus: 0),
        CreditPack(name: "Popular", credits: 100, applications: 110, price: "$59", perEach: "$0.54 each", bonus: 10),
        CreditPack(name: "Pro", credits: 300, applications: 340, price: "$149", perEach: "$0.44 each", bonus: 40)
    ]
}
