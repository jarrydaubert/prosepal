import ProsePalAPI
import SwiftUI

/// Which product surface the paywall shows, in priority order: an in-flight
/// load always wins, an empty catalogue explains itself, plans render last.
enum MomentPaywallProductPresentation: Equatable {
    case loading
    case unavailable(message: String)
    case plans([SubscriptionProduct])

    static func current(
        isLoadingSubscriptions: Bool,
        products: [SubscriptionProduct],
        errorMessage: String?
    ) -> MomentPaywallProductPresentation {
        if isLoadingSubscriptions {
            return .loading
        }
        if products.isEmpty {
            return .unavailable(
                message: errorMessage ?? SubscriptionError.notConfigured.userSafeMessage
            )
        }
        return .plans(products)
    }
}

struct MomentPaywallSheet: View {
    @Bindable var account: MomentAccountModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    paywallTopChrome
                    paywallHero
                    paywallFeaturePanel
                    productSection
                    purchaseActionSection
                    paywallFinePrint
                    accountSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .background {
                MomentAtmosphericBackground(isCareful: true)
            }
            .momentNavigationBarColorScheme()
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            #endif
            .task {
                await account.loadSubscriptionProducts(source: "paywall")
            }
        }
    }

    private var paywallTopChrome: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 42, height: 42)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .background(Color.prosePalPaper.opacity(0.74), in: Circle())
            .accessibilityLabel("Close").accessibilityIdentifier("paywall.close")

            Spacer(minLength: 12)

            Button {
                Task {
                    await account.restorePurchases(source: "paywall")
                    if account.isPremiumUnlocked {
                        dismiss()
                    }
                }
            } label: {
                Text(account.isRestoringPurchases ? "Restoring" : "Restore")
                    .font(.body.weight(.medium))
                    .frame(minHeight: 42, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .disabled(account.isRestoringPurchases).accessibilityIdentifier("paywall.restore").accessibilityLabel(String(localized: "Restore purchases")).accessibilityValue(account.isRestoringPurchases ? String(localized: "In progress") : String(localized: "Ready"))
        }
        .padding(.top, 0)
    }

    private var paywallHero: some View {
        VStack(spacing: 8) {
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 58, height: 58)
                .background(
                    LinearGradient(
                        colors: [
                            Color.prosePalCoral.opacity(0.20),
                            Color.prosePalCare.opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )

            Text("A room of your own.")
                .font(.system(size: 32, weight: .regular, design: .serif).italic())
                .foregroundStyle(Color.prosePalInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text("More drafts and refines, every register of tone, and a voice profile that remembers how you write.")
                .font(.subheadline)
                .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 312)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var paywallFeaturePanel: some View {
        VStack(spacing: 0) {
            MomentPremiumFeatureRow(
                systemImage: "arrow.up.circle",
                title: "More drafts and refines",
                detail: "Higher limits for the messages you shape"
            )
            MomentPaywallDivider()
            MomentPremiumFeatureRow(
                systemImage: "book.closed",
                title: "Your voice profile",
                detail: "ProsePal learns your cadence over time"
            )
            MomentPaywallDivider()
            MomentPremiumFeatureRow(
                systemImage: "lock",
                title: "Kept private",
                detail: "Your pages never train a model"
            )
        }
        .padding(.vertical, 2)
        .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: Color.prosePalCoralDeep.opacity(0.07), radius: 12, x: 0, y: 6)
    }

    @ViewBuilder
    private var purchaseActionSection: some View {
        if !account.subscriptionProducts.isEmpty {
            VStack(spacing: 9) {
                Button {
                    Task {
                        await account.purchasePremium(source: "paywall")
                        if account.isPremiumUnlocked {
                            dismiss()
                        }
                    }
                } label: {
                    Text(account.isPurchasingPremium ? "Working..." : "Continue")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.prosePalCoral)
                .disabled(account.isPurchasingPremium || account.isLoadingSubscriptions).accessibilityIdentifier("paywall.purchase").accessibilityLabel(String(localized: "Purchase Pro")).accessibilityValue(account.isPurchasingPremium ? String(localized: "In progress") : String(localized: "Ready"))

                Text(account.premiumRenewalDisclosureText)
                    .font(.caption2)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Account")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    Text(account.isSignedIn ? "Purchases are connected to your Apple account." : "Sign in with Apple to connect purchases to you.")
                        .font(.subheadline)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !account.isSignedIn {
                MomentAppleSignInControl(account: account, source: "paywall", height: 48)
            }
        }
        .padding(13)
        .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
    }

    private var paywallFinePrint: some View {
        HStack(spacing: 8) {
            Text("Cancel anytime")
            Text("·")
            Link("Terms", destination: MomentSettingsExternalLinks.terms)
            Text("·")
            Link("Privacy", destination: MomentSettingsExternalLinks.privacy)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Color.prosePalSlate.opacity(0.74))
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var productSection: some View {
        switch MomentPaywallProductPresentation.current(
            isLoadingSubscriptions: account.isLoadingSubscriptions,
            products: account.subscriptionProducts,
            errorMessage: account.subscriptionErrorMessage
        ) {
        case .loading:
            MomentPaywallLoadingRow()
        case .unavailable(let message):
            MomentPaywallUnavailableRow(
                message: message,
                onRetry: {
                    Task {
                        await account.loadSubscriptionProducts(source: "paywall_retry")
                    }
                }
            )
        case .plans(let products):
            VStack(spacing: 10) {
                ForEach(products) { product in
                    Button {
                        account.selectSubscriptionProduct(product)
                    } label: {
                        MomentPaywallPlanRow(
                            title: product.displayName,
                            subtitle: product.durationLabel ?? "Premium access",
                            price: product.displayPrice,
                            badge: product.isRecommended ? "Best value" : nil,
                            isSelected: account.selectedSubscriptionProductID == product.id
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct MomentPremiumFeatureRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}

private struct MomentPaywallDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.11))
            .frame(height: 0.5)
            .padding(.leading, 62)
    }
}

struct MomentPaywallPlanRow: View {
    let title: String
    let subtitle: String
    let price: String
    let badge: String?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(isSelected ? Color.prosePalCoral : Color.prosePalSlate.opacity(0.42))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.prosePalCoralDeep)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.prosePalCoral.opacity(0.13), in: Capsule())
                    }
                }

                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
            }

            Spacer(minLength: 10)

            Text(price)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.prosePalInk)
        }
        .padding(16)
        .background(Color.prosePalPaper.opacity(isSelected ? 0.98 : 0.86), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? Color.prosePalCoral.opacity(0.32) : Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MomentPaywallLoadingRow: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.prosePalCoral)

            VStack(alignment: .leading, spacing: 3) {
                Text("Loading subscription options")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)
                Text("This should only take a moment.")
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .accessibilityElement(children: .combine).accessibilityLabel(String(localized: "Loading subscription options")).accessibilityValue(String(localized: "In progress")).accessibilityIdentifier("paywall.products.loading")
    }
}

private struct MomentPaywallUnavailableRow: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.prosePalCoralDeep)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Subscription options unavailable")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)
                    Text(message)
                        .font(.callout)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                onRetry()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.prosePalCoral)
        }
        .padding(14)
        .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
