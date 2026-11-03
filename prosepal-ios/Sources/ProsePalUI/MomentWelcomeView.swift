import SwiftUI
import ProsePalDomain

struct MomentWelcomeView: View {
    @Bindable var account: MomentAccountModel
    let onStart: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selectedPage: MomentOnboardingPage = .welcome
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            MomentOnboardingDots(selection: selectedPage)
                .padding(.top, 12)
                .padding(.bottom, 2)

            GeometryReader { proxy in
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 22 : 0) {
                            Color.clear
                                .frame(height: 0)
                                .id(MomentOnboardingScrollAnchor.top)
                                .accessibilityHidden(true)

                            if !dynamicTypeSize.isAccessibilitySize {
                                Spacer(minLength: 0)
                            }

                            MomentOnboardingPanel(page: selectedPage)
                                .id(selectedPage)
                                .transition(pageTransition)

                            if dynamicTypeSize.isAccessibilitySize {
                                onboardingFooter
                                    .padding(.top, 6)
                            } else {
                                Spacer(minLength: 0)
                            }
                        }
                        .frame(
                            minHeight: max(360, proxy.size.height),
                            alignment: dynamicTypeSize.isAccessibilitySize ? .top : .center
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, dynamicTypeSize.isAccessibilitySize ? 18 : 0)
                        .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? 20 : 0)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: selectedPage) { _, _ in
                        resetAccessibilityScroll(using: scrollProxy)
                    }
                }
            }

            if !dynamicTypeSize.isAccessibilitySize {
                onboardingFooter
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 10)
                    .padding(.bottom, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: reduceMotion || hasAppeared ? 0 : 14)
        .task {
            guard !hasAppeared else { return }
            if reduceMotion {
                hasAppeared = true
            } else {
                withAnimation(.spring(response: 0.56, dampingFraction: 0.88)) {
                    hasAppeared = true
                }
            }
        }
        .tint(.prosePalCoral)
        .preferredColorScheme(.light)
        .onChange(of: account.isSignedIn) { wasSignedIn, isSignedIn in
            if !wasSignedIn && isSignedIn {
                onStart()
            }
        }
    }

    private var horizontalPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 24 : 26
    }

    private var onboardingFooter: some View {
        MomentOnboardingFooter(
            page: selectedPage,
            account: account,
            onPrimary: handlePrimaryAction
        )
    }

    private var pageTransition: AnyTransition {
        .opacity.combined(with: .move(edge: .trailing))
    }

    private func resetAccessibilityScroll(using scrollProxy: ScrollViewProxy) {
        guard dynamicTypeSize.isAccessibilitySize else { return }

        if reduceMotion {
            scrollProxy.scrollTo(MomentOnboardingScrollAnchor.top, anchor: .top)
        } else {
            withAnimation(.easeInOut(duration: 0.18)) {
                scrollProxy.scrollTo(MomentOnboardingScrollAnchor.top, anchor: .top)
            }
        }
    }

    private func handlePrimaryAction() {
        switch selectedPage.primaryAction {
        case .advance:
            advance()
        case .complete:
            onStart()
        }
    }

    private func advance() {
        guard let nextPage = selectedPage.next else { return }

        if reduceMotion {
            selectedPage = nextPage
        } else {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.9)) {
                selectedPage = nextPage
            }
        }
    }
}

private enum MomentOnboardingScrollAnchor {
    static let top = "moment.onboarding.scrollTop"
}

enum MomentOnboardingPage: Int, CaseIterable, Identifiable {
    case welcome
    case howItWorks
    case privacy
    case ready

    var id: Int { rawValue }

    var next: MomentOnboardingPage? {
        MomentOnboardingPage(rawValue: rawValue + 1)
    }

    var primaryAction: MomentOnboardingPrimaryAction {
        self == .ready ? .complete : .advance
    }

    var primaryTitle: String {
        switch self {
        case .welcome:
            "Begin writing"
        case .howItWorks, .privacy:
            "Next"
        case .ready:
            "Start writing"
        }
    }

    var primarySystemImage: String? {
        switch self {
        case .ready:
            "arrow.right"
        default:
            nil
        }
    }

    var showsAccountSignIn: Bool {
        self == .welcome
    }

    var accessibilityName: String {
        switch self {
        case .welcome:
            "Welcome"
        case .howItWorks:
            "How it works"
        case .privacy:
            "Privacy promise"
        case .ready:
            "Ready"
        }
    }
}

enum MomentOnboardingPrimaryAction: Equatable {
    case advance
    case complete
}

private struct MomentOnboardingDots: View {
    let selection: MomentOnboardingPage

    var body: some View {
        HStack(spacing: 6) {
            ForEach(MomentOnboardingPage.allCases) { page in
                Capsule()
                    .fill(page == selection ? Color.prosePalCoral : Color.prosePalCoral.opacity(0.20))
                    .frame(width: page == selection ? 22 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.22), value: selection)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding step \(selection.rawValue + 1) of \(MomentOnboardingPage.allCases.count)")
        .accessibilityIdentifier("moment.onboarding.progress")
    }
}

private struct MomentOnboardingPanel: View {
    let page: MomentOnboardingPage

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 40
    @ScaledMetric(relativeTo: .title) private var compactTitleSize = 34
    @ScaledMetric(relativeTo: .title) private var readyTitleSize = 36

    var body: some View {
        VStack(spacing: 0) {
            switch page {
            case .welcome:
                welcomePanel
            case .howItWorks:
                howItWorksPanel
            case .privacy:
                privacyPanel
            case .ready:
                readyPanel
            }
        }
        .frame(maxWidth: panelWidth)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("moment.onboarding.\(page.accessibilityName.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }

    private var panelWidth: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 316 : 330
    }

    private var heroBadgeSize: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 58 : 78
    }

    private var titleTopSpacing: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 14 : 22
    }

    private var welcomeTitleSize: CGFloat {
        resolvedTitleSize(titleSize, accessibilityCap: 58)
    }

    private var compactResolvedTitleSize: CGFloat {
        resolvedTitleSize(compactTitleSize, accessibilityCap: 52)
    }

    private var readyResolvedTitleSize: CGFloat {
        resolvedTitleSize(readyTitleSize, accessibilityCap: 54)
    }

    private var welcomePanel: some View {
        VStack(spacing: 0) {
            MomentSymbolBadge(systemImage: "pencil.and.scribble", style: .hero, size: heroBadgeSize)

            Text("Welcome to ProsePal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.prosePalCoralDeep)
                .padding(.top, titleTopSpacing)

            MomentOnboardingTitle(
                firstLine: "Find the words",
                secondLinePrefix: "you ",
                italicText: "mean.",
                size: welcomeTitleSize
            )

            onboardingBody("Bring the rough version. ProsePal helps you shape it — clearer, warmer, truer — and keeps it sounding like you.")
        }
    }

    private var howItWorksPanel: some View {
        VStack(spacing: 0) {
            MomentOnboardingDemo()

            MomentOnboardingTitle(
                firstLine: "Rough in,",
                secondLinePrefix: "",
                italicText: "right words out.",
                size: compactResolvedTitleSize
            )
            .padding(.top, titleTopSpacing)

            onboardingBody("Type how you'd say it to yourself. Choose a tone. ProsePal does the polishing.")
        }
    }

    private var privacyPanel: some View {
        VStack(spacing: 0) {
            MomentSymbolBadge(systemImage: "lock", style: .heroCare, size: heroBadgeSize)

            MomentOnboardingTitle(
                firstLine: "Your words",
                secondLinePrefix: "",
                italicText: "stay yours.",
                size: compactResolvedTitleSize
            )
            .padding(.top, titleTopSpacing)

            onboardingBody("Drafts are processed privately and never used to train models. Delete anything, anytime.")

            MomentOnboardingPrivacyList()
                .padding(.top, 18)
        }
    }

    private var readyPanel: some View {
        VStack(spacing: 0) {
            MomentSymbolBadge(systemImage: "paperplane.fill", style: .hero, size: heroBadgeSize)

            MomentOnboardingTitle(
                firstLine: nil,
                secondLinePrefix: "You're ",
                italicText: "ready.",
                size: readyResolvedTitleSize
            )
            .padding(.top, titleTopSpacing)

            onboardingBody("Start with someone who matters. Add what you want them to know, then ask ProsePal for a draft.")
        }
    }

    private func onboardingBody(_ text: String) -> some View {
        Text(text)
            .font(dynamicTypeSize.isAccessibilitySize ? .system(.body, design: .serif) : .system(.title3, design: .serif))
            .lineSpacing(5)
            .foregroundStyle(Color.prosePalSlate)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? 314 : 300)
    }

    private func resolvedTitleSize(_ size: CGFloat, accessibilityCap: CGFloat) -> CGFloat {
        dynamicTypeSize.isAccessibilitySize ? min(size, accessibilityCap) : size
    }
}

private struct MomentOnboardingTitle: View {
    let firstLine: String?
    let secondLinePrefix: String
    let italicText: String
    let size: CGFloat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            if let firstLine {
                Text(firstLine)
            }

            HStack(spacing: 0) {
                if !secondLinePrefix.isEmpty {
                    Text(secondLinePrefix)
                }

                Text(italicText)
                    .italic()
            }
        }
        .font(.system(size: size, weight: .medium, design: .serif))
        .foregroundStyle(Color.prosePalInk)
        .lineSpacing(dynamicTypeSize.isAccessibilitySize ? 4 : 1)
        .minimumScaleFactor(0.82)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, dynamicTypeSize.isAccessibilitySize ? 4 : 6)
        .padding(.bottom, dynamicTypeSize.isAccessibilitySize ? 10 : 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityAddTraits(.isHeader)
    }

    private var accessibilityTitle: String {
        [firstLine, "\(secondLinePrefix)\(italicText)"]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

private struct MomentOnboardingDemo: View {
    var body: some View {
        VStack(spacing: 7) {
            MomentOnboardingDemoRow(
                label: "You write",
                text: "cant make sunday, sorry",
                isPolished: false
            )

            Image(systemName: "arrow.down")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.prosePalCoral)
                .accessibilityHidden(true)

            MomentOnboardingDemoRow(
                label: "ProsePal",
                text: "I'm so sorry, but I won't be able to make it on Sunday.",
                isPolished: true
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You write: cant make sunday, sorry. ProsePal: I'm so sorry, but I won't be able to make it on Sunday.")
    }
}

private struct MomentOnboardingDemoRow: View {
    let label: String
    let text: String
    let isPolished: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(isPolished ? Color.prosePalCoralDeep : Color.prosePalSlate.opacity(0.72))

            Text(text)
                .font(isPolished ? .system(.body, design: .serif) : .system(.callout))
                .lineSpacing(isPolished ? 3 : 0)
                .foregroundStyle(isPolished ? Color.prosePalInk : Color.prosePalSlate.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, isPolished ? 14 : 13)
                .padding(.vertical, isPolished ? 12 : 11)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isPolished ? Color.prosePalPaper : Color.prosePalCard.opacity(0.72))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isPolished
                                        ? Color.prosePalNavy.opacity(0.12)
                                        : Color.prosePalSlate.opacity(0.22),
                                    style: StrokeStyle(
                                        lineWidth: isPolished ? 0.7 : 0.8,
                                        dash: isPolished ? [] : [4, 3]
                                    )
                                )
                        }
                        .shadow(
                            color: isPolished ? Color.prosePalCoralDeep.opacity(0.10) : Color.clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MomentOnboardingPrivacyList: View {
    private let items = [
        "On-device drafts by default",
        "No training on your text",
        "Export or erase in one tap"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.prosePalCare)
                        .frame(width: 17)
                        .accessibilityHidden(true)

                    Text(item)
                        .font(.system(.callout))
                        .foregroundStyle(Color.prosePalSlate)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: 290, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct MomentOnboardingFooter: View {
    let page: MomentOnboardingPage
    @Bindable var account: MomentAccountModel
    let onPrimary: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button {
                onPrimary()
            } label: {
                MomentOnboardingButtonLabel(
                    title: page.primaryTitle,
                    systemImage: page.primarySystemImage
                )
            }
            .buttonStyle(MomentOnboardingButtonStyle())
            .accessibilityIdentifier("moment.onboarding.primary")

            if page.showsAccountSignIn && account.isAppleSignInConfigured {
                MomentAppleSignInControl(
                    account: account,
                    source: "onboarding",
                    height: 52
                )
                .accessibilityIdentifier("moment.onboarding.signIn")
            }
        }
        .animation(.easeInOut(duration: 0.18), value: page)
    }
}

private struct MomentOnboardingButtonLabel: View {
    let title: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .accessibilityHidden(true)
            }

            Text(title)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MomentOnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 17)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(Color.prosePalCoral)
            .clipShape(Capsule())
            .shadow(
                color: Color.prosePalCoralDeep.opacity(0.16),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview("Onboarding") {
    MomentWelcomeView(
        account: MomentAccountModel(
            clientContext: ClientContext(appVersion: "1.0", buildNumber: "1")
        )
    ) {}
}
