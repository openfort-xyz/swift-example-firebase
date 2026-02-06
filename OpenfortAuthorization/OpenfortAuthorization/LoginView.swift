//
//  ContentView.swift
//  OpenfortAuthorization
//
//  Created by Pavel Gurkovskii on 2025-06-16.
//

import SwiftUI
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
    @StateObject private var homeViewModel = HomeViewModel()

    @State private var useBiometrics: Bool = false
    @State private var currentNonce: String?

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

                            // Divider
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
                            .padding(.top, 16)
                            .padding(.bottom, 8)

                            // Social buttons
                            socialButtonsView

                            HStack {
                                Text("Don't have an account?")
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
            } else {
                HomeView(viewModel: homeViewModel).onAppear {
                    homeViewModel.onLogout = {
                        isSignedIn = false
                        toastMessage = "Signed Out!"
                        showToast = true
                    }
                }
            }
        }
        .onAppear {
            Task {
                await checkExistingSession()
            }
        }
    }

    @ViewBuilder
    private var socialButtonsView: some View {
        VStack(spacing: 10) {
            // Sign in with Apple via Firebase
            SignInWithAppleButton(.signIn, onRequest: { request in
                let nonce = randomNonceString()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
            }, onCompletion: { result in
                switch result {
                case .success(let auth):
                    guard
                        let appleCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                        let tokenData = appleCredential.identityToken,
                        let idToken = String(data: tokenData, encoding: .utf8),
                        !idToken.isEmpty,
                        let nonce = currentNonce
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
                            // Create Firebase credential from Apple token and sign in
                            let firebaseCredential = OAuthProvider.credential(
                                providerID: AuthProviderID.apple,
                                idToken: idToken,
                                rawNonce: nonce
                            )
                            try await Auth.auth().signIn(with: firebaseCredential)
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
            .frame(maxWidth: .infinity, minHeight: 48, maxHeight: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Toggle("Require Face ID / Touch ID before signing in", isOn: $useBiometrics)
                .font(.footnote)
                .tint(.blue)
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

    // Check for existing Firebase session on launch
    private func checkExistingSession() async {
        if Auth.auth().currentUser != nil {
            isSignedIn = true
            toastMessage = "Welcome back!"
            showToast = true
        }
    }

    private func signIn() async {
        isLoading = true
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            isLoading = false
            toastMessage = "Signed in!"
            showToast = true
            isSignedIn = true
        } catch {
            toastMessage = "Failed to sign in: \(error.localizedDescription)"
            isLoading = false
            showToast = true
        }
    }

    private func continueAsGuest() async {
        isLoading = true
        do {
            try? Auth.auth().signOut()
            try await Auth.auth().signInAnonymously()
            isSignedIn = true
            toastMessage = "Signed in as Guest!"
        } catch {
            toastMessage = "Failed to sign in as Guest: \(error.localizedDescription)"
        }
        isLoading = false
        showToast = true
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
