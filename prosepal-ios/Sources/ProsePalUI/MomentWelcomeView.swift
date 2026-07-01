import SwiftUI

struct MomentWelcomeView: View {
    let onStart: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPage: MomentOnboardingPage = .welcome
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            MomentOnboardingDots(selection: selectedPage)
                .padding(.top, 12)
                .padding(.bottom, 2)

            GeometryReader { proxy in
                ScrollView {
                    VStack {
                        Spacer(minLength: 0)

                        MomentOnboardingPanel(page: selectedPage)
                            .id(selectedPage)
                            .transition(pageTransition)

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: max(360, proxy.size.height), alignment: .center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 26)
                }
                .scrollIndicators(.hidden)
            }

            MomentOnboardingFooter(
                page: selectedPage,
                onPrimary: handlePrimaryAction,
                onSecondary: handleSecondaryAction
            )
            .padding(.horizontal, 26)
            .padding(.top, 10)
            .padding(.bottom, 14)
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
        .accessibilityIdentifier("moment.onboarding")
    }

    private var pageTransition: AnyTransition {
        .opacity.combined(with: .move(edge: .trailing))
    }

    private func handlePrimaryAction() {
        switch selectedPage {
        case .welcome, .howItWorks, .privacy:
            advance()
        case .ready:
            onStart()
        }
    }

    private func handleSecondaryAction() {
        onStart()
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

private enum MomentOnboardingPage: Int, CaseIterable, Identifiable {
    case welcome
    case howItWorks
    case privacy
    case ready

    var id: Int { rawValue }

    var next: MomentOnboardingPage? {
        MomentOnboardingPage(rawValue: rawValue + 1)
    }

    var primaryTitle: String {
        switch self {
        case .welcome:
            "Begin writing"
        case .howItWorks, .privacy:
            "Next"
        case .ready:
            "Turn on gentle reminders"
        }
    }

    var primarySystemImage: String? {
        switch self {
        case .ready:
            "bell"
        default:
            nil
        }
    }

    var secondaryTitle: String? {
        switch self {
        case .welcome:
            "I already have an account"
        case .howItWorks, .privacy:
            nil
        case .ready:
            "Maybe later"
        }
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
        .frame(maxWidth: 330)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("moment.onboarding.\(page.accessibilityName.lowercased().replacingOccurrences(of: " ", with: "-"))")
    }

    private var welcomePanel: some View {
        VStack(spacing: 0) {
            MomentSymbolBadge(systemImage: "pencil.and.scribble", style: .hero, size: 78)

            Text("Welcome to ProsePal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.prosePalCoralDeep)
                .padding(.top, 22)

            MomentOnboardingTitle(
                firstLine: "Find the words",
                secondLinePrefix: "you ",
                italicText: "mean.",
                size: titleSize
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
                size: compactTitleSize
            )
            .padding(.top, 22)

            onboardingBody("Type how you'd say it to yourself. Choose a tone. ProsePal does the polishing.")
        }
    }

    private var privacyPanel: some View {
        VStack(spacing: 0) {
            MomentSymbolBadge(systemImage: "lock", style: .heroCare, size: 78)

            MomentOnboardingTitle(
                firstLine: "Your words",
                secondLinePrefix: "",
                italicText: "stay yours.",
                size: compactTitleSize
            )
            .padding(.top, 22)

            onboardingBody("Drafts are processed privately and never used to train models. Delete anything, anytime.")

            MomentOnboardingPrivacyList()
                .padding(.top, 18)
        }
    }

    private var readyPanel: some View {
        VStack(spacing: 0) {
            MomentSymbolBadge(systemImage: "paperplane.fill", style: .hero, size: 78)

            MomentOnboardingTitle(
                firstLine: nil,
                secondLinePrefix: "You're ",
                italicText: "ready.",
                size: readyTitleSize
            )
            .padding(.top, 22)

            onboardingBody("Want a quiet nudge when a message has been waiting? No noise — just a hand when you need one.")
        }
    }

    private func onboardingBody(_ text: String) -> some View {
        Text(text)
            .font(.system(.title3, design: .serif))
            .lineSpacing(5)
            .foregroundStyle(Color.prosePalSlate)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 300)
    }
}

private struct MomentOnboardingTitle: View {
    let firstLine: String?
    let secondLinePrefix: String
    let italicText: String
    let size: CGFloat

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
        .lineSpacing(1)
        .minimumScaleFactor(0.82)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 6)
        .padding(.bottom, 8)
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
    let onPrimary: () -> Void
    let onSecondary: () -> Void

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
            .buttonStyle(MomentOnboardingButtonStyle(variant: .primary))
            .accessibilityIdentifier("moment.onboarding.primary")

            if let secondaryTitle = page.secondaryTitle {
                Button {
                    onSecondary()
                } label: {
                    MomentOnboardingButtonLabel(title: secondaryTitle)
                }
                .buttonStyle(MomentOnboardingButtonStyle(variant: .ghost))
                .accessibilityIdentifier("moment.onboarding.secondary")
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
    enum Variant {
        case primary
        case ghost
    }

    let variant: Variant

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(foregroundStyle)
            .padding(.horizontal, variant == .primary ? 28 : 24)
            .padding(.vertical, variant == .primary ? 17 : 14)
            .frame(maxWidth: .infinity, minHeight: variant == .primary ? 58 : 52)
            .background(background)
            .clipShape(Capsule())
            .shadow(
                color: variant == .primary ? Color.prosePalCoralDeep.opacity(0.16) : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var foregroundStyle: Color {
        switch variant {
        case .primary:
            .white
        case .ghost:
            .prosePalCoralDeep
        }
    }

    private var background: some ShapeStyle {
        switch variant {
        case .primary:
            return Color.prosePalCoral
        case .ghost:
            return Color.clear
        }
    }
}

#Preview("Onboarding") {
    MomentWelcomeView {}
}
