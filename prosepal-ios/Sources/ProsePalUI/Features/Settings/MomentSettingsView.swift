import Foundation
import ProsePalAPI
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum MomentSettingsExternalLinks {
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacy = URL(string: "https://prosepal.app/privacy")!
    static let manageSubscriptions = URL(string: "https://apps.apple.com/account/subscriptions")!
    static let supportEmail = "support@prosepal.app"
    static let support = URL(string: "mailto:\(supportEmail)")!
}

struct MomentSettingsView: View {
    @Bindable var account: MomentAccountModel
    let onlineWritingPermissionStore: any OnlineWritingPermissionStoring
    let onDone: () -> Void
    @State private var supportNotice: String?
    @State private var isStatusWashVisible = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                settingsTopChrome

                if let notice = account.notice {
                    Label(notice.title, systemImage: notice.systemImage)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.prosePalSlate)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.prosePalPaper.opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityIdentifier(notice.accessibilityIdentifier ?? "account.notice")
                }

                MomentSettingsProfileCard(
                    initials: profileInitials,
                    title: profileTitle,
                    detail: profileDetail,
                    isPremium: account.isPremiumUnlocked
                )

                MomentSettingsGroup("Writing") {
                    MomentSettingsStaticRows(
                        rows: MomentSettingsStaticRowDescriptor.writing(
                            isRelationshipVaultPersistent: account.runtimeReadiness.isRelationshipVaultPersistent
                        )
                    )
                }

                MomentSettingsGroup("Privacy") {
                    MomentSettingsRowContent(
                        row: .privateDraftPrivacy(
                            isConfigured: account.runtimeReadiness.isPrivateDraftConfigured
                        )
                    )
                    MomentSettingsDivider()
                    settingsNavigationRow(
                        systemImage: "shield.checkered",
                        title: "Privacy & data",
                        accessibilityIdentifier: "settings.privacyData"
                    ) {
                        MomentPrivacyDataView(
                            account: account,
                            onlineWritingPermissionStore: onlineWritingPermissionStore
                        )
                    }
                }

                MomentSettingsGroup("Subscription") {
                    settingsNavigationRow(
                        systemImage: "checkmark.seal",
                        title: "ProsePal Pro",
                        subtitle: account.isPremiumUnlocked ? "Active" : "Upgrade available",
                        accessibilityIdentifier: "settings.plan"
                    ) {
                        MomentPlanDetailView(account: account)
                    }
                    MomentSettingsDivider()
                    settingsButtonRow(
                        systemImage: "lifepreserver",
                        title: "Help & support",
                        showsChevron: true
                    ) {
                        copySupportEmail()
                    }
                }

                if let supportNotice {
                    Label(supportNotice, systemImage: "checkmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.prosePalSlate)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                MomentSettingsGroup("Account & data") {
                    if account.isSignedIn {
                        settingsButtonRow(
                            systemImage: "rectangle.portrait.and.arrow.right",
                            title: "Sign out"
                        ) {
                            Task {
                                await account.signOut()
                            }
                        }
                        MomentSettingsDivider()
                        settingsButtonRow(
                            systemImage: "trash",
                            title: account.isDeletingAccount ? "Deleting account" : "Delete account",
                            role: .destructive,
                            accessibilityIdentifier: "settings.account.delete.request"
                        ) {
                            account.requestAccountDeletion()
                        }
                        .disabled(account.isDeletingAccount)
                        .accessibilityValue(account.isDeletingAccount ? String(localized: "In progress") : String(localized: "Ready"))
                        MomentSettingsDivider()
                    } else {
                        MomentAppleSignInControl(account: account, source: "settings")
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                        MomentSettingsDivider()
                    }

                    settingsButtonRow(
                        systemImage: "arrow.clockwise",
                        title: account.isRestoringPurchases ? "Restoring purchases" : "Restore purchases",
                        subtitle: account.subscriptionErrorMessage,
                        accessibilityIdentifier: "settings.restorePurchases"
                    ) {
                        Task {
                            await account.restorePurchases(source: "settings")
                        }
                    }
                    .disabled(account.isRestoringPurchases)
                    .accessibilityValue(account.isRestoringPurchases ? String(localized: "In progress") : String(localized: "Ready"))
                    MomentSettingsDivider()
                    settingsNavigationRow(
                        systemImage: "checkmark.seal",
                        title: "Relationship memory",
                        subtitle: account.runtimeReadiness.isRelationshipVaultPersistent ? "Stored on device" : "Temporary",
                        accessibilityIdentifier: "settings.relationshipMemory"
                    ) {
                        RelationshipMemoryVaultView()
                    }
                    MomentSettingsDivider()
                    MomentSettingsRowContent(
                        row: .privateDraftReadiness(
                            isConfigured: account.runtimeReadiness.isPrivateDraftConfigured
                        )
                    )
                    MomentSettingsDivider()
                    MomentSettingsRowContent(
                        row: .sensitiveWriting(
                            isConfigured: account.runtimeReadiness.isCarefulGatewayConfigured
                        )
                    )
                }

                MomentSettingsGroup("Legal") {
                    Link(destination: MomentSettingsExternalLinks.support) {
                        MomentSettingsRowContent(
                            systemImage: "envelope",
                            title: "Contact support",
                            showsChevron: true
                        )
                    }
                    .buttonStyle(.plain)
                    MomentSettingsDivider()
                    Link(destination: MomentSettingsExternalLinks.terms) {
                        MomentSettingsRowContent(
                            systemImage: "doc.text",
                            title: "Terms",
                            showsChevron: true
                        )
                    }
                    .buttonStyle(.plain)
                    MomentSettingsDivider()
                    Link(destination: MomentSettingsExternalLinks.privacy) {
                        MomentSettingsRowContent(
                            systemImage: "hand.raised",
                            title: "Privacy Policy",
                            showsChevron: true
                        )
                    }
                    .buttonStyle(.plain)
                }

                MomentSettingsGroup("About") {
                    MomentSettingsStaticRows(rows: [.version(versionText), .direction])
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 42)
        }
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y > 8
        } action: { _, isScrolled in
            isStatusWashVisible = isScrolled
        }
        .background {
            MomentAtmosphericBackground(isCareful: false)
        }
        .overlay(alignment: .top) {
            MomentSettingsStatusWash()
                .opacity(isStatusWashVisible ? 1 : 0)
                .animation(.easeInOut(duration: 0.16), value: isStatusWashVisible)
        }
        .tint(.prosePalCoral)
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .confirmationDialog(
            "Delete account?",
            isPresented: Binding(
                get: { account.isConfirmingAccountDeletion },
                set: { if !$0 { account.cancelAccountDeletion() } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) {
                Task {
                    await account.confirmAccountDeletion()
                }
            }
            .accessibilityLabel(String(localized: "Confirm delete account"))
            .accessibilityIdentifier("settings.account.delete.confirm")
            Button("Cancel", role: .cancel) {
                account.cancelAccountDeletion()
            }
        } message: {
            Text("This deletes your ProsePal account and app data connected to it.")
        }
    }

    private var settingsTopChrome: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button("Done") {
                onDone()
            }
            .font(.title3.weight(.regular))
            .foregroundStyle(Color.prosePalCoralDeep)
            .buttonStyle(.plain)
            .frame(minHeight: 36, alignment: .leading)
            .accessibilityIdentifier("settings.done")

            Text("Settings")
                .font(.system(size: 38, weight: .medium, design: .serif))
                .foregroundStyle(Color.prosePalInk)
                .lineLimit(1)
                .minimumScaleFactor(0.84)
        }
        .padding(.top, 4)
    }

    private func settingsButtonRow(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        showsChevron: Bool = false,
        role: ButtonRole? = nil,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            MomentSettingsRowContent(
                systemImage: systemImage,
                title: title,
                subtitle: subtitle,
                showsChevron: showsChevron,
                isDestructive: role == .destructive
            )
        }
        .buttonStyle(.plain)
        .momentSettingsAccessibilityIdentifier(accessibilityIdentifier)
    }

    private func settingsNavigationRow<Destination: View>(
        systemImage: String,
        title: String,
        subtitle: String? = nil,
        accessibilityIdentifier: String? = nil,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            MomentSettingsRowContent(
                systemImage: systemImage,
                title: title,
                subtitle: subtitle,
                showsChevron: true
            )
        }
        .buttonStyle(.plain)
        .momentSettingsAccessibilityIdentifier(accessibilityIdentifier)
    }

    private var profileInitials: String {
        guard let firstCharacter = (account.signedInEmail ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .first
        else {
            return "PP"
        }
        return String(firstCharacter).uppercased()
    }

    private var profileTitle: String {
        account.isSignedIn ? "Apple account" : "ProsePal"
    }

    private var profileDetail: String {
        if account.isSignedIn {
            return account.signedInEmail ?? "Signed in with Apple"
        }
        return "Private on this iPhone"
    }

    private var versionText: String {
        account.appVersionDisplayText
    }

    private func copySupportEmail() {
        #if canImport(UIKit)
        UIPasteboard.general.string = MomentSettingsExternalLinks.supportEmail
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(MomentSettingsExternalLinks.supportEmail, forType: .string)
        #endif
        supportNotice = "Copied support email"
    }
}

private extension View {
    @ViewBuilder
    func momentSettingsAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}
