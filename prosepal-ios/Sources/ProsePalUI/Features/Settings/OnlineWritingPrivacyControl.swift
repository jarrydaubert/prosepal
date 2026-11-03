import ProsePalAPI
import SwiftUI

struct OnlineWritingPrivacyControl: View {
    let store: any OnlineWritingPermissionStoring
    let onRevoked: () -> Void

    @State private var permissionState: OnlineWritingPermissionState

    init(
        store: any OnlineWritingPermissionStoring,
        onRevoked: @escaping () -> Void
    ) {
        self.store = store
        self.onRevoked = onRevoked
        _permissionState = State(initialValue: store.state())
    }

    var body: some View {
        VStack(spacing: 0) {
            row(
                systemImage: "network",
                title: "Online writing",
                subtitle: "Sends entered details only when an online draft or adjustment is needed",
                trailing: permissionState == .currentGrant ? "On" : "Off"
            )

            if permissionState == .currentGrant {
                divider
                Button(role: .destructive) {
                    store.revoke()
                    permissionState = store.state()
                    onRevoked()
                } label: {
                    row(
                        systemImage: "network.slash",
                        title: "Turn off online writing",
                        subtitle: "Future online drafts and adjustments will ask first",
                        isDestructive: true
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("privacy.onlineWriting.revoke")
            }
        }
        .onAppear {
            permissionState = store.state()
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.prosePalNavy.opacity(0.11))
            .frame(height: 0.5)
            .padding(.leading, 64)
    }

    private func row(
        systemImage: String,
        title: String,
        subtitle: String,
        trailing: String? = nil,
        isDestructive: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(isDestructive ? Color.red.opacity(0.78) : Color.prosePalSlate)
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isDestructive ? Color.red.opacity(0.84) : Color.prosePalInk)
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(Color.prosePalSlate.opacity(0.78))
                    .lineLimit(2)
            }

            Spacer(minLength: 10)

            if let trailing {
                Text(trailing)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(Color.prosePalSlate.opacity(0.68))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(minHeight: 82)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview("Online writing off") {
    OnlineWritingPrivacyControl(store: PreviewOnlineWritingPermissionStore(state: .notGranted)) {}
        .padding()
}

#Preview("Online writing on") {
    OnlineWritingPrivacyControl(store: PreviewOnlineWritingPermissionStore(state: .currentGrant)) {}
        .padding()
}

private final class PreviewOnlineWritingPermissionStore: OnlineWritingPermissionStoring, @unchecked Sendable {
    private var permissionState: OnlineWritingPermissionState

    init(state: OnlineWritingPermissionState) {
        permissionState = state
    }

    func state() -> OnlineWritingPermissionState { permissionState }
    func grantCurrentPolicy() { permissionState = .currentGrant }
    func revoke() { permissionState = .notGranted }
}
