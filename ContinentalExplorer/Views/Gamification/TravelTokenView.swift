import SwiftUI

// MARK: - Travel Token View (Wallet)
struct TravelTokenView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ObservedObject var tokenService: TravelTokenService

    @State private var selectedTab: TokenTab = .wallet
    @State private var showRedeemAlert: Bool = false
    @State private var selectedItem: RedeemableItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Wallet Header
                    walletHeader

                    // Tab Selector
                    tabSelector

                    // Tab Content
                    switch selectedTab {
                    case .wallet:
                        walletContent
                    case .redeem:
                        redeemContent
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xxl)
            }
            .background(DesignTokens.Colors.backgroundDark)
            .navigationTitle("Travel Tokens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Redeem Item", isPresented: $showRedeemAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Redeem") {
                    if let item = selectedItem {
                        _ = tokenService.redeemItem(item)
                    }
                }
            } message: {
                if let item = selectedItem {
                    Text("Redeem \(item.name) for \(item.cost) CT?")
                }
            }
        }
    }

    // MARK: - Wallet Header
    private var walletHeader: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Token Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignTokens.Colors.primaryAccent, DesignTokens.Colors.secondaryAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            Text(TravelTokenService.tokenName)
                .font(Typography.headline(.h4))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            // Balance
            Text(tokenService.formattedBalance)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(DesignTokens.Colors.primaryAccent)

            // Earned / Spent Summary
            HStack(spacing: DesignTokens.Spacing.xl) {
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(DesignTokens.Colors.success)
                        Text(String(format: "%.1f CT", tokenService.totalEarned))
                            .font(Typography.bodyMedium(.sm))
                            .foregroundStyle(DesignTokens.Colors.success)
                    }
                    Text("Total Earned")
                        .font(Typography.body(.xxs))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }

                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(DesignTokens.Colors.danger)
                        Text(String(format: "%.1f CT", tokenService.totalSpent))
                            .font(Typography.bodyMedium(.sm))
                            .foregroundStyle(DesignTokens.Colors.danger)
                    }
                    Text("Total Spent")
                        .font(Typography.body(.xxs))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(TokenTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(DesignTokens.Animation.spring) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: tab.iconName)
                        Text(tab.rawValue)
                    }
                    .font(Typography.bodyMedium(.sm))
                    .foregroundStyle(selectedTab == tab ? .white : DesignTokens.Colors.textTertiary)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(selectedTab == tab ? DesignTokens.Colors.primaryAccent : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.pill))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.Spacing.xs)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.pill))
    }

    // MARK: - Wallet Content
    private var walletContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Transaction History")
                .font(Typography.headline(.h5))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if tokenService.transactions.isEmpty {
                emptyState
            } else {
                ForEach(tokenService.transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
    }

    // MARK: - Redeem Content
    private var redeemContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Redeem Tokens")
                .font(Typography.headline(.h5))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            ForEach(tokenService.redeemableItems) { item in
                RedeemableItemRow(
                    item: item,
                    canAfford: tokenService.balance >= Double(item.cost)
                ) {
                    selectedItem = item
                    showRedeemAlert = true
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "bitcoinsign.circle")
                .font(.system(size: 40))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
            Text("No transactions yet.\nEarn tokens by completing trips and achievements!")
                .font(Typography.body(.sm))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.xxl)
    }
}

// MARK: - Token Tab
enum TokenTab: String, CaseIterable {
    case wallet = "Wallet"
    case redeem = "Redeem"

    var iconName: String {
        switch self {
        case .wallet: return "creditcard.fill"
        case .redeem: return "gift.fill"
        }
    }
}

// MARK: - Sub Components
struct TransactionRow: View {
    let transaction: TravelToken

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(transaction.timestamp)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: transaction.type.iconName)
                .font(.system(size: 18))
                .foregroundStyle(transaction.isPositive ? DesignTokens.Colors.success : DesignTokens.Colors.danger)
                .frame(width: 36, height: 36)
                .background((transaction.isPositive ? DesignTokens.Colors.success : DesignTokens.Colors.danger).opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(Typography.bodyMedium(.sm))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(timeAgo)
                    .font(Typography.body(.xxs))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(Typography.bodyMedium(.md))
                .foregroundStyle(transaction.isPositive ? DesignTokens.Colors.success : DesignTokens.Colors.danger)
        }
        .padding(DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
    }
}

struct RedeemableItemRow: View {
    let item: RedeemableItem
    let canAfford: Bool
    let onRedeem: () -> Void

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: item.iconName)
                .font(.system(size: 22))
                .foregroundStyle(DesignTokens.Colors.primaryAccent)
                .frame(width: 44, height: 44)
                .background(DesignTokens.Colors.primaryAccent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(Typography.bodyMedium(.md))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(item.description)
                    .font(Typography.body(.sm))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Spacer()

            Button {
                onRedeem()
            } label: {
                Text("\(item.cost) CT")
                    .font(Typography.bodyMedium(.sm))
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(canAfford ? DesignTokens.Colors.primaryAccent : DesignTokens.Colors.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.pill))
            }
            .buttonStyle(.plain)
            .disabled(!canAfford)
        }
        .padding(DesignTokens.Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .opacity(canAfford ? 1.0 : 0.6)
    }
}
