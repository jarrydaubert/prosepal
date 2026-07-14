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
        } else {
            fallbackButton
        }
        #else
        fallbackButton
        #endif
    }

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
