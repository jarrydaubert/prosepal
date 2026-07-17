import Foundation
import ProsePalDomain
import SwiftUI

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

struct MomentAppleSignInControl: View {
    @Bindable var account: MomentAccountModel
    let source: String
    var height: CGFloat = 52

    var body: some View {
        VStack(spacing: 7) {
            signInButton

            if account.isSigningIn {
                ProgressView {
                    Text(String(localized: "Signing in"))
                }
                .controlSize(.small)
                .accessibilityLabel(String(localized: "Signing in"))
                .accessibilityValue(String(localized: "In progress"))
                .accessibilityIdentifier("auth.apple.progress.\(source)")
            }
        }
    }

    @ViewBuilder
    private var signInButton: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--prosepal-ui-testing") {
            uiTestButton
        } else {
            platformSignInButton
        }
        #else
        platformSignInButton
        #endif
    }

    @ViewBuilder
    private var platformSignInButton: some View {
        #if canImport(AuthenticationServices)
        if account.isAppleSignInConfigured {
            SignInWithAppleButton(.continue) { request in
                request.nonce = account.beginAppleSignInRequest(source: source)
            } onCompletion: { result in
                handle(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(account.isSigningIn)
            .accessibilityLabel(String(localized: "Continue with Apple"))
            .accessibilityValue(account.isSigningIn ? String(localized: "In progress") : String(localized: "Ready"))
            .accessibilityIdentifier("auth.apple.entry.\(source)")
        } else {
            fallbackButton
        }
        #else
        fallbackButton
        #endif
    }

    #if DEBUG
    private var uiTestButton: some View {
        Button {
            guard account.beginAppleSignInRequest(source: source) != nil else { return }
            Task { @MainActor in
                await account.completeAppleSignIn(
                    idToken: "ui-test-identity-token",
                    authorizationCode: "ui-test-authorization-code",
                    appleUserID: "ui-test-apple-user",
                    source: source
                )
            }
        } label: {
            Label(String(localized: "Continue with Apple"), systemImage: "apple.logo")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .controlSize(.large)
        .tint(.prosePalNavy)
        .disabled(account.isSigningIn)
        .accessibilityValue(account.isSigningIn ? String(localized: "In progress") : String(localized: "Ready"))
        .accessibilityIdentifier("auth.apple.entry.\(source)")
    }
    #endif

    private var fallbackButton: some View {
        Button {
            _ = account.beginAppleSignInRequest(source: source)
        } label: {
            Label(String(localized: "Continue with Apple"), systemImage: "apple.logo")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .controlSize(.large)
        .tint(.prosePalNavy)
        .disabled(account.isSigningIn)
        .accessibilityValue(account.isSigningIn ? String(localized: "In progress") : String(localized: "Ready"))
        .accessibilityIdentifier("auth.apple.entry.\(source)")
    }

    #if canImport(AuthenticationServices)
    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                Task { @MainActor in
                    await account.completeAppleSignIn(
                        idToken: nil,
                        authorizationCode: nil,
                        appleUserID: nil,
                        source: source
                    )
                }
                return
            }

            let token = credential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
            let authorizationCode = credential.authorizationCode.flatMap {
                String(data: $0, encoding: .utf8)
            }

            Task { @MainActor in
                await account.completeAppleSignIn(
                    idToken: token,
                    authorizationCode: authorizationCode,
                    appleUserID: credential.user,
                    source: source
                )
            }
        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                account.cancelAppleSignIn(source: source)
            } else {
                account.failAppleSignIn(source: source, category: "authorization_error")
            }
        }
    }
    #endif
}

#Preview {
    MomentAppleSignInControl(
        account: MomentAccountModel(
            clientContext: ClientContext(appVersion: "1.0", buildNumber: "1")
        ),
        source: "preview"
    )
    .padding()
}
