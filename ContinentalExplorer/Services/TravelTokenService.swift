import Foundation
import Combine

// MARK: - Travel Token Service (Blockchain-lite)
@MainActor
final class TravelTokenService: ObservableObject {

    // MARK: - Published
    @Published var balance: Double = 0.0
    @Published var transactions: [TravelToken] = []
    @Published var pendingTransactions: [TravelToken] = []
    @Published var isProcessing: Bool = false

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private let maxTransactionHistory = 100

    // MARK: - Token Name
    static let tokenSymbol = "CT"
    static let tokenName = "Continental Token"

    init() {
        loadSampleTransactions()
    }

    // MARK: - Token Operations
    func earnTokens(amount: Double, description: String, achievementID: UUID? = nil) {
        let transaction = TravelToken(
            amount: amount,
            type: .earned,
            description: description,
            relatedAchievementID: achievementID
        )

        transactions.insert(transaction, at: 0)
        if transactions.count > maxTransactionHistory {
            transactions = Array(transactions.prefix(maxTransactionHistory))
        }

        balance += amount
    }

    func spendTokens(amount: Double, description: String) -> Bool {
        guard balance >= amount else { return false }

        let transaction = TravelToken(
            amount: amount,
            type: .spent,
            description: description
        )

        transactions.insert(transaction, at: 0)
        if transactions.count > maxTransactionHistory {
            transactions = Array(transactions.prefix(maxTransactionHistory))
        }

        balance -= amount
        return true
    }

    func bonusTokens(amount: Double, description: String) {
        let transaction = TravelToken(
            amount: amount,
            type: .bonus,
            description: description
        )

        transactions.insert(transaction, at: 0)
        if transactions.count > maxTransactionHistory {
            transactions = Array(transactions.prefix(maxTransactionHistory))
        }
        balance += amount
    }

    // MARK: - Statistics
    var totalEarned: Double {
        transactions.filter { $0.type == .earned || $0.type == .bonus || $0.type == .referral }.reduce(0) { $0 + $1.amount }
    }

    var totalSpent: Double {
        transactions.filter { $0.type == .spent }.reduce(0) { $0 + $1.amount }
    }

    var formattedBalance: String {
        String(format: "%.1f %@", balance, Self.tokenSymbol)
    }

    // MARK: - Redeemable Items
    var redeemableItems: [RedeemableItem] {
        [
            RedeemableItem(name: "Premium Map Style", description: "Unlock satellite HD mode", cost: 50, iconName: "map.fill"),
            RedeemableItem(name: "Voice Pack: British", description: "British English navigation voice", cost: 30, iconName: "speaker.wave.3.fill"),
            RedeemableItem(name: "Custom Car Icon", description: "Sports car navigation icon", cost: 20, iconName: "car.fill"),
            RedeemableItem(name: "Offline Region Pack", description: "Download extra offline regions", cost: 40, iconName: "arrow.down.circle.fill"),
            RedeemableItem(name: "Ad-Free Week", description: "Remove ads for 7 days", cost: 15, iconName: "xmark.circle.fill"),
            RedeemableItem(name: "XP Booster 2x", description: "Double XP for 24 hours", cost: 25, iconName: "bolt.fill"),
        ]
    }

    func redeemItem(_ item: RedeemableItem) -> Bool {
        return spendTokens(amount: Double(item.cost), description: "Redeemed: \(item.name)")
    }

    // MARK: - Sample Data
    private func loadSampleTransactions() {
        balance = 12.5

        transactions = [
            TravelToken(amount: 5.0, type: .bonus, description: "Welcome bonus", timestamp: Date().addingTimeInterval(-86400 * 5)),
            TravelToken(amount: 2.5, type: .earned, description: "Trip completed: Paris → Lyon", timestamp: Date().addingTimeInterval(-86400 * 3)),
            TravelToken(amount: 1.0, type: .earned, description: "Community report verified", timestamp: Date().addingTimeInterval(-86400 * 2)),
            TravelToken(amount: 2.0, type: .earned, description: "Achievement: First Steps", timestamp: Date().addingTimeInterval(-86400)),
            TravelToken(amount: 2.0, type: .earned, description: "Daily login streak x3", timestamp: Date().addingTimeInterval(-3600)),
        ]
    }
}

// MARK: - Redeemable Item
struct RedeemableItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let cost: Int
    let iconName: String
}
