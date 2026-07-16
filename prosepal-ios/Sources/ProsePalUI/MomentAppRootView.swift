import Foundation
import Observation
import ProsePalAPI
import ProsePalDomain
import SwiftData
import SwiftUI

enum MomentRootTab: String, CaseIterable, Hashable, Sendable {
    case moment
    case saved
    case settings

    var title: String {
        switch self {
        case .moment:
            String(localized: "Write")
        case .saved:
            String(localized: "Drafts")
        case .settings:
            String(localized: "Settings")
        }
    }

    var systemImage: String {
        switch self {
        case .moment:
            "square.and.pencil"
        case .saved:
            "rectangle.stack"
        case .settings:
            "gearshape"
        }
    }

    var accessibilityIdentifier: String {
        "root.tab.\(rawValue)"
    }
}

public struct MomentAppRootView: View {
    @Environment(\.scenePhase) private var scenePhase

    private let launchStore: MomentLaunchStore
    private let sharedLaunchStore: SharedMomentLaunchStore
    private let diagnostics: NativeDiagnosticsLogger

    @State private var model: MomentModel
    @State private var account: MomentAccountModel
    @State private var welcomeState: MomentWelcomeState
    @State private var selectedTab: MomentRootTab = .moment
    @State private var didLogStartup = false
    @Query(sort: \SavedMomentDraftRecord.createdAt, order: .reverse)
    private var savedDrafts: [SavedMomentDraftRecord]

    public init(
        service: any MessageWritingService,
        account: MomentAccountModel,
        welcomeState: @autoclosure @escaping () -> MomentWelcomeState = MomentWelcomeState(),
        launchStore: MomentLaunchStore = MomentLaunchStore(),
        sharedLaunchStore: SharedMomentLaunchStore = SharedMomentLaunchStore(),
        draftRecoveryStore: any MomentDraftRecoveryStoring = MomentDraftRecoveryStore(),
        diagnostics: NativeDiagnosticsLogger = .shared
    ) {
        self.launchStore = launchStore
        self.sharedLaunchStore = sharedLaunchStore
        self.diagnostics = diagnostics
        _model = State(initialValue: MomentModel(
            service: service,
            draftRecoveryStore: draftRecoveryStore
        ))
        _account = State(initialValue: account)
        _welcomeState = State(initialValue: welcomeState())
    }

    public var body: some View {
        Group {
            if welcomeState.hasCompletedWelcome {
                MomentRootTabs(
                    model: model,
                    account: account,
                    selection: $selectedTab
                )
            } else {
                MomentWelcomeView(account: account) {
                    welcomeState.completeWelcome()
                }
                .overlay(alignment: .top) {
                    // Keeps outcome notices (for example the account-deletion
                    // confirmation) visible after the tab hierarchy that
                    // normally presents them has been unmounted.
                    if let notice = account.notice {
                        Label(notice.title, systemImage: notice.systemImage)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Color.prosePalSlate)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .accessibilityIdentifier(notice.accessibilityIdentifier ?? "account.notice")
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: welcomeState.hasCompletedWelcome)
        .onAppear(perform: handleAppear)
        .onChange(of: welcomeState.hasCompletedWelcome, handleWelcomeCompletion)
        .onChange(of: account.accountLifecycleResetToken, handleAccountLifecycleReset)
        .onChange(of: scenePhase, handleScenePhaseChange)
        .onOpenURL(perform: consumeDeepLink)
        .task {
            await account.loadInitialState()
        }
    }

    /// View-layer half of the account-deletion lifecycle. The account model
    /// has already wiped the vault and session; this clears every remaining
    /// surface that could show or replay the deleted account's content, then
    /// resets onboarding, which swaps `MomentRootTabs` out of the hierarchy so
    /// the previous Write and Settings views cannot stay mounted.
    private func handleAccountLifecycleReset(_ oldValue: Int, _ newValue: Int) {
        guard newValue > oldValue else { return }
        model.resetForAccountDeletion()
        _ = launchStore.consume()
        _ = sharedLaunchStore.consume()
        selectedTab = .moment
        welcomeState.reset()
    }

    private func handleAppear() {
        logStartupIfNeeded()
        consumePendingLaunch()
    }

    private func logStartupIfNeeded() {
        guard !didLogStartup else { return }
        didLogStartup = true
        diagnostics.appStarted(
            hasCompletedOnboarding: welcomeState.hasCompletedWelcome,
            savedMessageCount: savedDrafts.count
        )
        diagnostics.runtimeReadiness(account.runtimeReadiness)
    }

    private func handleWelcomeCompletion(_ oldValue: Bool, _ completed: Bool) {
        if completed {
            consumePendingLaunch()
        }
    }

    private func handleScenePhaseChange(_ oldValue: ScenePhase, _ newValue: ScenePhase) {
        if newValue == .background {
            model.appDidEnterBackground()
        }
    }

    private func consumePendingLaunch() {
        guard let request = launchStore.consume() else { return }
        applyLaunchRequest(request)
    }

    private func consumeDeepLink(_ url: URL) {
        guard let deepLink = MomentDeepLink(url: url) else { return }
        var request = deepLink.launchRequest
        if request.source == MomentLaunchSource.shareExtension,
           let sharedPayload = sharedLaunchStore.consume(),
           let sharedText = sharedPayload.text ?? sharedPayload.sourceURL?.absoluteString {
            request.sharedText = sharedText
        }
        applyLaunchRequest(request)
    }

    private func applyLaunchRequest(_ request: MomentLaunchRequest) {
        selectedTab = .moment
        diagnostics.momentLaunchConsumed(request)
        model.applyLaunchRequest(request)
    }
}

@MainActor
@Observable
public final class MomentWelcomeState {
    public nonisolated static let defaultCompletionKey = "prosepal.native.momentWelcomeCompleted.v1"

    public private(set) var hasCompletedWelcome: Bool

    @ObservationIgnored private let store: UserDefaults
    @ObservationIgnored private let completionKey: String

    public init(
        store: UserDefaults = .standard,
        completionKey: String = MomentWelcomeState.defaultCompletionKey
    ) {
        self.store = store
        self.completionKey = completionKey
        self.hasCompletedWelcome = store.bool(forKey: completionKey)
    }

    public func completeWelcome() {
        hasCompletedWelcome = true
        store.set(true, forKey: completionKey)
    }

    /// Returns the app to the first-run welcome experience. Used by the
    /// account-deletion lifecycle so a deleted account's device immediately
    /// routes back to onboarding, both in this run and after relaunch.
    public func reset() {
        hasCompletedWelcome = false
        store.removeObject(forKey: completionKey)
    }
}

private struct MomentRootTabs: View {
    @Bindable var model: MomentModel
    @Bindable var account: MomentAccountModel
    @Binding var selection: MomentRootTab

    var body: some View {
        TabView(selection: $selection) {
            Tab(value: MomentRootTab.moment) {
                NavigationStack {
                    MomentSheetView(
                        model: model,
                        account: account,
                        onOpenDrafts: { selection = .saved },
                        onOpenSettings: { selection = .settings }
                    )
                    #if os(iOS)
                    .toolbar(.hidden, for: .navigationBar)
                    #endif
                    .momentNavigationBarColorScheme()
                }
            } label: {
                rootTabLabel(.moment)
            }

            Tab(value: MomentRootTab.saved) {
                NavigationStack {
                    SavedMomentDraftsView {
                        selection = .moment
                    }
                    .momentNavigationBarColorScheme()
                }
            } label: {
                rootTabLabel(.saved)
            }

            Tab(value: MomentRootTab.settings) {
                NavigationStack {
                    MomentSettingsView(account: account) {
                        selection = .moment
                    }
                    .momentNavigationBarColorScheme()
                }
            } label: {
                rootTabLabel(.settings)
            }
        }
        .tint(.prosePalCoral)
        .preferredColorScheme(.light)
        .onChange(of: selection) { oldValue, newValue in
            if oldValue == .moment, newValue != .moment {
                model.composerDidDismiss()
            }
        }
    }

    private func rootTabLabel(_ tab: MomentRootTab) -> some View {
        Label(tab.title, systemImage: tab.systemImage)
            .accessibilityIdentifier(tab.accessibilityIdentifier)
    }
}

#Preview("Root navigation") {
    MomentRootTabsPreview()
}

private struct MomentRootTabsPreview: View {
    private let container: ModelContainer

    @State private var model: MomentModel
    @State private var account: MomentAccountModel
    @State private var selection: MomentRootTab = .moment

    init() {
        let mockClient = MockMomentDraftClient(bundle: MomentDraftBundle(
            messageText: "I have been thinking about you and wanted to say this properly.",
            lane: .mock
        ))
        container = try! RelationshipVaultContainerFactory.makeEphemeral()
        _model = State(initialValue: MomentModel(
            service: RoutingMessageWritingService(
                privateClient: mockClient,
                carefulClient: mockClient
            )
        ))
        _account = State(initialValue: MomentAccountModel(
            clientContext: ClientContext(appVersion: "1.0", buildNumber: "1")
        ))
    }

    var body: some View {
        MomentRootTabs(
            model: model,
            account: account,
            selection: $selection
        )
        .modelContainer(container)
    }
}
