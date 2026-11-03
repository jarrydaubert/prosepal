import ProsePalAPI
import SwiftUI

struct MomentPlanStatusPresentation: Equatable {
    let subtitle: String
    let price: String

    static func current(
        entitlement: SubscriptionEntitlement,
        activeProduct: SubscriptionProduct?,
        selectedProduct: SubscriptionProduct?
    ) -> MomentPlanStatusPresentation {
        let product = activeProduct ?? selectedProduct
        return MomentPlanStatusPresentation(
            subtitle: subtitle(entitlement: entitlement, product: product),
            price: price(product: product)
        )
    }

    private static func subtitle(
        entitlement: SubscriptionEntitlement,
        product: SubscriptionProduct?
    ) -> String {
        if let expiresAt = entitlement.expiresAt {
            if let duration = product?.durationLabel, !duration.isEmpty {
                return "\(displayDurationLabel(duration)) · renews \(expiresAt.formatted(.dateTime.month(.abbreviated).day().year()))"
            }

            return "Renews \(expiresAt.formatted(.dateTime.month(.abbreviated).day().year()))"
        }

        if let duration = product?.durationLabel, !duration.isEmpty {
            return "\(displayDurationLabel(duration)) · active"
        }

        return "Active subscription"
    }

    private static func price(product: SubscriptionProduct?) -> String {
        guard let product else {
            return "Unlocked"
        }

        if let duration = product.durationLabel?.lowercased(), !duration.isEmpty {
            return "\(product.displayPrice)\(priceSuffix(for: duration))"
        }

        return product.displayPrice
    }

    private static func displayDurationLabel(_ duration: String) -> String {
        let normalized = duration.lowercased()
        if normalized.contains("year") {
            return "Yearly"
        }
        if normalized.contains("month") {
            return "Monthly"
        }
        if normalized.contains("week") {
            return "Weekly"
        }
        return duration
    }

    private static func priceSuffix(for duration: String) -> String {
        if duration.contains("year") {
            return "/yr"
        }
        if duration.contains("month") {
            return "/mo"
        }
        if duration.contains("week") {
            return "/wk"
        }
        return " / \(duration)"
    }
}

struct MomentPlanDetailView: View {
    @Bindable var account: MomentAccountModel
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingPaywall = false

    private var statusPresentation: MomentPlanStatusPresentation {
        MomentPlanStatusPresentation.current(
            entitlement: account.subscriptionEntitlement,
            activeProduct: account.activeSubscriptionProduct,
            selectedProduct: account.selectedSubscriptionProduct
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                topChrome

                if let notice = account.notice {
                    planNotice(notice)
                }

                if account.isPremiumUnlocked {
                    proPlanContent
                } else {
                    freePlanContent
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 42)
        }
        .scrollIndicators(.hidden)
        .background {
            MomentAtmosphericBackground(isCareful: account.isPremiumUnlocked)
        }
        .tint(.prosePalCoral)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .sheet(isPresented: $isShowingPaywall) {
            MomentPaywallSheet(account: account)
        }
        .task {
            if account.isPremiumUnlocked &&
                account.subscriptionProducts.isEmpty &&
                account.isSubscriptionConfigured {
                await account.loadSubscriptionProducts(source: "plan_detail")
            }
        }
    }

    private var topChrome: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                dismiss()
            } label: {
                Label("Settings", systemImage: "chevron.left")
                    .font(.body.weight(.regular))
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.prosePalCoralDeep)
            .frame(minHeight: 36, alignment: .leading)

            Text("Your plan")
                .font(.system(.title2, design: .serif).weight(.medium))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private var freePlanContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            freeUsageCard
            freeUpsellCard
        }
    }

    private var freeUsageCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Free plan")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    MomentPlanBadge(text: "Free", style: .outline)
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Starter refines")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    Spacer(minLength: 8)

                    Text("service-managed")
                        .font(.caption2.monospaced().weight(.medium))
                        .foregroundStyle(Color.prosePalSlate.opacity(0.64))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                MomentPlanMeter(progress: nil, tint: .prosePalWarning)

                Text("Usage updates after ProsePal syncs your allowance.")
                    .font(.caption)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.70))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .planCardSurface(cornerRadius: 18, shadow: true)
        .accessibilityElement(children: .combine)
    }

    private var freeUpsellCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center, spacing: 12) {
                MomentPlanCrest(systemImage: "pencil.and.scribble", size: 44, cornerRadius: 14)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Go further with Pro")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.prosePalInk)

                    Text("For the messages that matter most")
                        .font(.footnote)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                MomentPlanFeatureLine(systemImage: "arrow.up.circle", title: "More drafts & refines")
                MomentPlanFeatureLine(systemImage: "book.closed", title: "A voice profile that's yours")
                MomentPlanFeatureLine(systemImage: "slider.horizontal.3", title: "Every tone & length")
            }

            Button {
                isShowingPaywall = true
            } label: {
                Label("See Pro", systemImage: "pencil.and.scribble")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.prosePalCoral)
            .accessibilityLabel("See Pro").accessibilityIdentifier("plan.openPaywall")
        }
        .padding(16)
        .planCardSurface(cornerRadius: 18, shadow: true)
    }

    private var proPlanContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            proStatusCard
            includedGroup
            manageGroup
        }
    }

    private var proStatusCard: some View {
        VStack(spacing: 5) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 24, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.prosePalPaper)
                .frame(width: 46, height: 46)
                .background(Color.prosePalPaper.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.bottom, 6)

            Text("ProsePal Pro")
                .font(.system(size: 24, weight: .medium, design: .serif))
                .foregroundStyle(Color.prosePalPaper)
                .lineLimit(1)
                .minimumScaleFactor(0.84)

            Text(statusPresentation.subtitle)
                .font(.footnote)
                .foregroundStyle(Color.prosePalPaper.opacity(0.84))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(statusPresentation.price)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.prosePalPaper)
                .padding(.top, 8)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.prosePalCoral,
                            Color.prosePalCoralDeep
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .shadow(color: Color.prosePalCoralDeep.opacity(0.18), radius: 18, x: 0, y: 10)
        .accessibilityElement(children: .combine).accessibilityIdentifier("plan.status.premium")
    }

    private var includedGroup: some View {
        planGroup("Included") {
            MomentPlanListRow(
                systemImage: "arrow.up.circle",
                title: "Higher writing limits",
                tint: .prosePalCare,
                trailingSystemImage: "checkmark"
            )
            MomentPlanDivider()
            MomentPlanListRow(
                systemImage: "person.crop.square",
                title: "Voice profile",
                subtitle: account.runtimeReadiness.isRelationshipVaultPersistent ? "Active & learning" : "Available with local vault",
                tint: .prosePalCare,
                trailingSystemImage: "checkmark"
            )
        }
    }

    private var manageGroup: some View {
        VStack(spacing: 0) {
            Link(destination: MomentSettingsExternalLinks.manageSubscriptions) {
                MomentPlanListRow(
                    systemImage: "receipt",
                    title: "Manage subscription",
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
        }
        .planCardSurface(cornerRadius: 18)
    }

    private func planNotice(_ notice: MomentAccountNotice) -> some View {
        Label(notice.title, systemImage: notice.systemImage)
            .font(.callout.weight(.semibold))
            .foregroundStyle(Color.prosePalSlate)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityElement(children: .combine)
    }

    private func planGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(Color.prosePalSlate.opacity(0.72))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .planCardSurface(cornerRadius: 18)
        }
    }
}

private struct MomentPlanBadge: View {
    enum Style {
        case outline
        case accent
    }

    let text: String
    var style: Style = .accent

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(style == .accent ? Color.prosePalPaper : Color.prosePalCoralDeep)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule(style: .continuous)
                    .fill(style == .accent ? Color.prosePalCoral : Color.prosePalCoral.opacity(0.10))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(Color.prosePalCoral.opacity(style == .accent ? 0 : 0.20), lineWidth: 1)
                    }
            }
    }
}

private struct MomentPlanCrest: View {
    let systemImage: String
    var size: CGFloat
    var cornerRadius: CGFloat

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.48, weight: .regular))
            .foregroundStyle(Color.prosePalCoralDeep)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [
                        Color.prosePalCoral.opacity(0.18),
                        Color.prosePalPaper.opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.08), lineWidth: 0.8)
            }
            .accessibilityHidden(true)
    }
}

private struct MomentPlanFeatureLine: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.prosePalCoralDeep)
                .frame(width: 22)
                .accessibilityHidden(true)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.prosePalSlate.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct MomentPlanMeter: View {
    let progress: CGFloat?
    var tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.prosePalNavy.opacity(0.10))

                if let progress {
                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(width: max(0, min(proxy.size.width, proxy.size.width * progress)))
                } else {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.opacity(0.26),
                                    tint.opacity(0.12)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(proxy.size.width * 0.38, 132))
                }
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

private struct MomentPlanListRow: View {
    let systemImage: String
    let title: String
    var subtitle: String?
    var tint: Color = .prosePalSlate
    var trailingSystemImage: String?
    var showsChevron = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(tint)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.prosePalInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)

                if let subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 10)

            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.prosePalSlate.opacity(0.48))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(minHeight: subtitle == nil ? 58 : 70)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct MomentPlanDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.11))
            .frame(height: 0.5)
            .padding(.leading, 64)
    }
}

private extension View {
    func planCardSurface(cornerRadius: CGFloat, shadow: Bool = false) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.prosePalPaper.opacity(0.94), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.prosePalNavy.opacity(0.10), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .shadow(color: shadow ? Color.prosePalCoralDeep.opacity(0.08) : Color.clear, radius: shadow ? 12 : 0, x: 0, y: shadow ? 6 : 0)
    }
}
