import SwiftUI

extension View {
    func onlineWritingPermissionAlert(model: MomentModel) -> some View {
        alert(
            "Use online writing?",
            isPresented: Bindable(model).isOnlineWritingPermissionRequestPresented
        ) {
            Button("Allow Online Writing") {
                model.allowOnlineWritingAndRetry()
            }
            .accessibilityIdentifier("onlineWriting.permission.allow")
            Button("Not Now", role: .cancel) {
                model.deferOnlineWriting()
            }
            .accessibilityIdentifier("onlineWriting.permission.notNow")
        } message: {
            Text("Some messages need ProsePal’s online writing service. The details you enter are sent securely to ProsePal and an AI provider to create or adjust your draft. Relationship Memory stays on this device. You can turn online writing off at any time in Privacy & Data.")
        }
    }
}
