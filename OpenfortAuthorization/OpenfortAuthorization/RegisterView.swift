//
//  RegisterView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift

struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var emailConfirmation: Bool = false
    @State private var isLoading: Bool = false
    @State private var error: String? = nil
    @State private var showToast: Bool = false
    @State private var showConnectWallet = false
    @State private var toastMessage: String = ""
    private var openfort = OFSDK.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack {
                    Spacer(minLength: 40)
                    VStack(alignment: .leading, spacing: 0) {
                        if emailConfirmation {
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.seal.fill")
                                    .resizable()
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Check your email to confirm")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("You've successfully signed up. Please check your email to confirm your account before signing in to the Openfort dashboard.")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                .padding(.leading, 2)
                            }
                            .padding()
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                        } else {
                            Text("Sign up for account")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.bottom, 24)
                            
                            VStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading) {
                                        Text("First name")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("First name", text: $firstName)
                                            .autocapitalization(.words)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                    VStack(alignment: .leading) {
                                        Text("Last name")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("Last name", text: $lastName)
                                            .autocapitalization(.words)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
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
                                    Text("Your password must be at least 8 characters including a lowercase letter, an uppercase letter, and a special character (e.g. !@#%&*).")
                                        .font(.caption2)
                                        .foregroundColor(error == "invalidPassword" ? .red : .gray)
                                        .fontWeight(error == "invalidPassword" ? .medium : .regular)
                                        .padding(.top, 3)
                                }
                            }
                            .padding(.bottom, 12)
                            
                            Button(action: {
                                Task {
                                    await signUp()
                                }
                            }) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                } else {
                                    Text("Get started today")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                            .disabled(isLoading)
                            .background(isLoading ? Color.gray.opacity(0.2) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.top, 8)
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                            Text("Or continue with")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                        }
                        .padding(.vertical, 16)
                        
                        VStack(spacing: 8) {
                            socialButton("Continue with Google", icon: "globe") {
                                handleSocialAuth(provider: .google)
                            }
                            socialButton("Continue with Twitter", icon: "bird") { handleSocialAuth(provider: .twitter)
                            }
                            socialButton("Continue with Facebook", icon: "f.square") { handleSocialAuth(provider: .facebook)
                            }
                            socialButton("Continue with Wallet", icon: "wallet.pass") {
                                showConnectWallet = true
                            }.sheet(isPresented: $showConnectWallet) {
                                ConnectWalletView(onSignIn: {
                                    dismiss()
                                })
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("By signing up, you accept ")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                            HStack(spacing: 0) {
                                Button(action: { openURL(URL(string: "https://www.openfort.io/terms")!) }) {
                                    Text("user terms")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .underline()
                                }
                                Text(", ")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Button(action: { openURL(URL(string: "https://www.openfort.io/privacy")!) }) {
                                    Text("privacy policy")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .underline()
                                }
                                Text(" and ")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Button(action: { openURL(URL(string: "https://www.openfort.io/developer-terms")!) }) {
                                    Text("developer terms of use")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .underline()
                                }
                                Text(".")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        HStack {
                            Text("Have an account?")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Button("Sign in") {
                                dismiss()
                            }
                            .foregroundColor(.blue)
                            .font(.subheadline)
                        }
                        .padding(.top, 18)
                    }
                    .padding(28)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 8)
                    
                    Spacer()
                }
                
                // Toast
                if showToast {
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
        }.onOpenURL { url in
            print("Opened from link:", url)
            
            if url.host == "login",
               let state = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                            .queryItems?
                            .first(where: { $0.name == "state" })?.value {
                print("State:", state)
                UserDefaults.standard.set(state, forKey: "openfort:email_verification_state")
                isLoading = false
                emailConfirmation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
    
    private func handleSocialAuth(provider: OFOAuthProvider) {
        Task {
            do {
                if let result = try await openfort.initOAuth(
                    params: OFInitOAuthParams(
                        provider: provider.rawValue,
                        options: ["redirectTo": AnyCodable(RedirectManager.makeLink(path: "login")?.absoluteString ?? "")]
                    )
                ), let urlString = result.url, let url = URL(string: urlString) {
                    openURL(url)
                }
                isLoading = false
                emailConfirmation = true
                toast("Successfully signed up with " + provider.rawValue.capitalized)
            } catch {
                toast("Failed to sign in with \(provider.rawValue.capitalized): \(error)")
            }
        }
    }
    
    func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
    
    func signUp() async {
        // Validate password
        guard checkPassword(password) else {
            error = "invalidPassword"
            toast("Your password must be at least 8 characters including a lowercase letter, an uppercase letter, and a special character (e.g. !@#%&*).")
            return
        }
        error = nil
        isLoading = true
        do {
            let result = try await openfort.signUpWith(params: OFSignUpWithEmailPasswordParams(email: email, password: password, options: OFSignUpWithEmailPasswordOptionsParams(data: ["name": "\(firstName) \(lastName)"])))

            // Check if email verification is required
            if let action = result?.action, action == "verify_email" {
                try await verifyEmail()
                UserDefaults.standard.set(email, forKey: "openfort:email")
                isLoading = false
                toast("Email verification sent! Check your email.")
                return
            }

            // Sign up successful
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isLoading = false
                emailConfirmation = true
                toast("Successfully signed up!")
            }
        } catch  {
            isLoading = false
            toast("Failed to sign up: \(error)")
            return
        }
    }
    
    private func verifyEmail() async throws {
        try await openfort.requestEmailVerification(params: OFRequestEmailVerificationParams(email: email, redirectUrl: RedirectManager.makeLink(path: "login")?.absoluteString ?? ""))
    }
    
    func checkPassword(_ pw: String) -> Bool {
        let lower = pw.range(of: "[a-z]", options: .regularExpression) != nil
        let upper = pw.range(of: "[A-Z]", options: .regularExpression) != nil
        let special = pw.range(of: "[!@#%&*]", options: .regularExpression) != nil
        let digit = pw.range(of: "\\d", options: .regularExpression) != nil
        return pw.count >= 8 && lower && upper && special && digit
    }
    
    func toast(_ message: String) {
        toastMessage = message
        withAnimation { showToast = true }
    }
    
    func socialButton(_ text: String, icon: String, action: @escaping () -> Void) -> some View {
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

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
