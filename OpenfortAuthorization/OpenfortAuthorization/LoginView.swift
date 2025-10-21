//
//  ContentView.swift
//  OpenfortAuthorization
//
//  Created by Pavel Gurkovskii on 2025-06-16.
//

import SwiftUI
import JavaScriptCore
import WebKit
import OpenfortSwift
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import CryptoKit
import UIKit

struct LoginView: View {
    
    @State private var email: String = "testing@fort.dev"
    @State private var password: String = "B3sF!JxJD3@727q"
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showForgotPassword = false
    @State private var showSignUp = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isSignedIn = false
    @State private var showConnectWallet = false
    @StateObject private var homeViewModel = HomeViewModel()
    
    @State private var useBiometrics: Bool = false
    @State private var currentNonce: String?
    
    private let openfort = OFSDK.shared
    
    var body: some View {
        NavigationView {
            if !isSignedIn {
                ZStack {
                    Color(.systemGroupedBackground).ignoresSafeArea()
                    VStack {
                        Spacer(minLength: 40)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Sign in to account")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.bottom, 24)
                            
                            VStack(spacing: 18) {
                                VStack(alignment: .leading) {
                                    Text("Email address")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("Email", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("Password")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack {
                                        if showPassword {
                                            TextField("Password", text: $password)
                                                .autocapitalization(.none)
                                        } else {
                                            SecureField("Password", text: $password)
                                                .autocapitalization(.none)
                                        }
                                        Button(action: { showPassword.toggle() }) {
                                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                HStack {
                                    Spacer()
                                    Button("Forgot password?") {
                                        showForgotPassword = true
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                            }
                            .padding(.bottom, 8)
                            
                            Button(action: {
                                Task {
                                    await signIn()
                                }
                            }) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                } else {
                                    Text("Sign in to account")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .disabled(isLoading)
                            .background(isLoading ? Color.gray.opacity(0.2) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.top, 12)
                            
                            Button(action: {
                                Task {
                                    await continueAsGuest()
                                }
                            }) {
                                Text("Continue as Guest")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1))
                            }
                            .padding(.top, 12)
                            
                            // Social buttons
                            socialButtonsView
                            
                            HStack {
                                Text("Don’t have an account?")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Button("Sign up") {
                                    showSignUp = true
                                }
                                .foregroundColor(.blue)
                                .font(.subheadline)
                            }
                            .padding(.top, 24)
                        }
                        .padding(28)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 8)
                        
                        Spacer()
                    }
                    if showToast {
                        toastView
                    }
                }
                // Modals
                .sheet(isPresented: $showForgotPassword) {
                    ForgotPasswordView()
                }
                .sheet(isPresented: $showSignUp) {
                    RegisterView()
                }
                .sheet(isPresented: $showConnectWallet) {
                    ConnectWalletView(onSignIn: {
                        showConnectWallet = false
                    })
                }
            } else {
                HomeView(viewModel: homeViewModel).onAppear {
                    homeViewModel.onLogout = {
                        isSignedIn = false
                        toastMessage = "Sigend Out!"
                        showToast = true
                    }
                }
            }
        }
        .onAppear {
            Task {
                await checkExistingSession()
                await verifyEmail()
            }
        }
    }
    
    @ViewBuilder
    private var socialButtonsView: some View {
        VStack(spacing: 8) {
            // Divider with centered label
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.gray.opacity(0.3))
                Text("Or continue with")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.gray.opacity(0.3))
            }
            .padding(.vertical, 16)

            // Social buttons
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    socialButton("Continue with Google", icon: "globe") { continueWithGoogle() }
                    socialButton("Continue with Twitter", icon: "bird") { continueWithTwitter() }
                }
                HStack(spacing: 8) {
                    socialButton("Continue with Facebook", icon: "f.square") { continueWithFacebook() }
                    socialButton("Continue with Wallet", icon: "wallet.pass") { continueWithWallet() }
                }

                // Sign in with Apple
                HStack(spacing: 8) {
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    }, onCompletion: { result in
                        switch result {
                        case .success(let auth):
                            guard
                                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                                let tokenData = credential.identityToken,
                                let idToken = String(data: tokenData, encoding: .utf8),
                                !idToken.isEmpty
                            else {
                                toastMessage = "Apple Sign-In: missing ID token"
                                showToast = true
                                return
                            }
                            Task {
                                do {
                                    if useBiometrics {
                                        let anchor = await currentPresentationAnchor()
                                        let manager = AppleAuthManager(presentationAnchor: anchor)
                                        _ = try await manager.authenticateWithBiometrics(reason: "Authenticate to continue")
                                    }
                                    _ = try await OFSDK.shared.loginWithIdToken(
                                        params: OFLoginWithIdTokenParams(provider: OFAuthProvider.apple.rawValue, token: idToken)
                                    )
                                    isSignedIn = true
                                    toastMessage = "Signed in with Apple!"
                                    showToast = true
                                } catch {
                                    toastMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                                    showToast = true
                                }
                            }
                        case .failure(let error):
                            toastMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                            showToast = true
                        }
                    })
                    .signInWithAppleButtonStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Toggle("Require Face ID / Touch ID before signing in", isOn: $useBiometrics)
                    .font(.footnote)
                    .tint(.blue)
            }
        }.onOpenURL { url in
            print("Opened from link:", url)
            if url.host == "login",
               let state = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                            .queryItems?
                            .first(where: { $0.name == "state" })?.value {
                print("State:", state)
            }
            // Handle OAuth redirect carrying access/refresh tokens and player id
            if url.host == "login", let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                let qp: [String: String] = comps.queryItems?.reduce(into: [:]) { dict, item in
                    if let v = item.value { dict[item.name] = v }
                } ?? [:]

                if let accessToken = qp["access_token"],
                   let refreshToken = qp["refresh_token"],
                   let playerId = qp["player_id"],
                   !accessToken.isEmpty, !refreshToken.isEmpty, !playerId.isEmpty {

                    isLoading = true
                    toastMessage = "Signing in..."
                    showToast = true

                    Task {
                        do {
                            // Store credentials into Openfort SDK
                            try await openfort.storeCredentials(params: OFStoreCredentialsParams(player: playerId, accessToken: accessToken, refreshToken: refreshToken))

                            // Consider user signed in and transition to Home
                            isSignedIn = true
                            isLoading = false
                            toastMessage = "Signed in!"
                            showToast = true
                        } catch {
                            isLoading = false
                            toastMessage = "Failed to store credentials: \(error.localizedDescription)"
                            showToast = true
                        }
                    }
                }
            }
        }
    }
    
    private func continueWithApple() {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let anchor = await currentPresentationAnchor()
                let apple = AppleAuthManager(presentationAnchor: anchor)
                // Optional local auth gate (uncomment if desired)
                // _ = try await apple.authenticateWithBiometrics(reason: "Authenticate to continue")
                let idToken = try await apple.performAppleSignIn()
                _ = try await OFSDK.shared.loginWithIdToken(params: OFLoginWithIdTokenParams(provider: OFAuthProvider.apple.rawValue, token: idToken))
                isSignedIn = true
                toastMessage = "Signed in with Apple!"
                showToast = true
            } catch {
                toastMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                showToast = true
            }
        }
    }
    
    private var toastView: some View {
        Group {
            Text(toastMessage)
                .padding()
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(10)
                .transition(.move(edge: .top))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showToast = false }
                    }
                }
                .zIndex(2)
        }
    }
    
    private func verifyEmail() async {
        if let email = UserDefaults.standard.string(forKey: "openfort:email"), let state = UserDefaults.standard.string(forKey: "openfort:email_verification_state") {
            do {
                try await OFSDK.shared.verifyEmail(params: OFVerifyEmailParams(email: email, state: state))
                isLoading = false
                toastMessage = "Email verified successfully!"
                showToast = true
            } catch {
                isLoading = false
                toastMessage = "Email not verified!"
                showToast = true
            }
            
            UserDefaults.standard.removeObject(forKey: "openfort:email")
            UserDefaults.standard.removeObject(forKey: "openfort:email_verification_state")
        }
    }
    
    // Check for existing Openfort session on launch
    private func checkExistingSession() async {
        isLoading = true
        defer { isLoading = false }
        let retrieveUser = {
            do {
                // Try to get the current user/session from Openfort
                if let _ = try await openfort.getUser() {
                    // If session exists, jump straight to Home
                    isSignedIn = true
                    // Optional: show a small toast
                    toastMessage = "Welcome back!"
                    showToast = true
                }
            } catch {
                // If fetching user fails, stay on login screen silently (or show a toast if desired)
                // toastMessage = "Failed to restore session: \(error.localizedDescription)"
                // showToast = true
            }
        }
        await retrieveUser()
    }
    
    private func signIn() async {
        isLoading = true
        let username = self.email
        let password = self.password
        
        do {
            _ = try await Auth.auth().signIn(withEmail: username, password: password)
            isLoading = false
            toastMessage = "Signed in!"
            showToast = true
            isSignedIn = true
        } catch {
            toastMessage = "Failed to sign in: \(error.localizedDescription)"
            isLoading = false
            showToast = true
            return
        }
    }
    
    private func loginWIthEmailPassword() async {
        do {
            let result = try await OFSDK.shared.loginWith(params: OFAuthEmailPasswordParams(email: email, password: password))
            print(result ?? "Empty response!")
        } catch {
            print("Failed to sign in: \(error.localizedDescription)")
            return
        }
    }
    
    private func continueAsGuest() async {
        
        isLoading = true
        do {
            _ = try await openfort.signUpGuest()
            isSignedIn = true
            toastMessage = "Signed in as Guest!"
        } catch {
            toastMessage = "Failed to sign in as Guest: \(error.localizedDescription)"
        }
        isLoading = false
        showToast = true
    }
    
    private func startOAuth(provider: OFAuthProvider, successMessage: String) {
        isLoading = true
        Task { [providerName = successMessage] in
            defer { isLoading = false }
            do {
                if let result = try await openfort.initOAuth(
                    params: OFInitOAuthParams(
                        provider: provider.rawValue,
                        options: ["redirectTo": AnyCodable(RedirectManager.makeLink(path: "login")?.absoluteString ?? "")]
                    )
                ), let urlString = result.url, let url = URL(string: urlString) {
                    await UIApplication.shared.open(url)
                }
                // If the call completes without throwing, consider the user signed in
                isSignedIn = true
                toastMessage = providerName
                showToast = true
            } catch {
                toastMessage = "\(successMessage.replacingOccurrences(of: "Signed in with ", with: "")) sign-in failed: \(error.localizedDescription)"
                showToast = true
            }
        }
    }

    private func continueWithGoogle() {
        startOAuth(provider: .google, successMessage: "Signed in with Google!")
    }
    
    private func continueWithTwitter() {
        startOAuth(provider: .twitter, successMessage: "Signed in with Twitter!")
    }
    
    private func continueWithFacebook() {
        startOAuth(provider: .facebook, successMessage: "Signed in with Facebook!")
    }
    
    private func continueWithWallet() {
        showConnectWallet = true
    }
    
    private func socialButton(_ text: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(text)
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .background(Color.white)
        .foregroundColor(.blue)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1))
    }
}

#Preview {
    LoginView()
}

private func currentPresentationAnchor() async -> ASPresentationAnchor {
    await (UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow } ?? UIWindow())
}

func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remaining = length
    
    while remaining > 0 {
        var bytes = [UInt8](repeating: 0, count: 16)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status != errSecSuccess { fatalError("SecRandomCopyBytes failed: \(status)") }
        bytes.forEach { b in
            if remaining == 0 { return }
            if b < charset.count {
                result.append(charset[Int(b)])
                remaining -= 1
            }
        }
    }
    return result
}

func sha256(_ input: String) -> String {
    let data = Data(input.utf8)
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
}
