//
//  ForgotPasswordView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-12.
//

import SwiftUI
import WebKit
import OpenfortSwift

struct ForgotPasswordView: View {
    // MARK: - State
    @State private var email: String = UserDefaults.standard.string(forKey: "openfort:email") ?? ""
    @State private var isLoading: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastType: ForgotPasswordStatusType = .none
    @State private var showToast: Bool = false
    @State private var showResetPassword = false
    @State private var resetState: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        // Card
                        VStack(alignment: .leading, spacing: 16) {
                            resetPasswordHeader
                            sendResetEmailButton
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Button("login") {
                                    dismiss()
                                }
                                .font(.footnote)
                            }
                            .padding(.top, 8)
                        }
                        .padding(24)
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                        .padding(.horizontal)
                        .padding(.top, 24)
                    }
                }
                toastView
            }
            .onAppear { Task { await checkExistingSession() } }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onOpenURL { url in
                print("Opened from link:", url)
                
                if url.host == "reset-password",
                   let state = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                                .queryItems?
                                .first(where: { $0.name == "state" })?.value {
                    print("State:", state)
                    resetState = state
                    showResetPassword = true
                }
            }.navigationDestination(isPresented: $showResetPassword) {
                ResetPasswordView(state: resetState, email: email)
            }
        }
    }

    // MARK: - Actions
    private func handleSubmit() async {
        guard !email.isEmpty else { return }
        isLoading = true
        showToast = false

        do {
            let redirect = redirectURLString()
            let params = OFRequestResetPasswordParams(email: email, redirectUrl: redirect)
            try await OFSDK.shared.requestResetPassword(params: params)
            toastMessage = "Successfully sent email"
            toastType = .success
            showToast = true
        } catch {
            toastMessage = "Error sending email"
            toastType = .error
            showToast = true
        }
        isLoading = false
    }
    
    private func checkExistingSession() async {
        do {
            if let _ = try await OFSDK.shared.getUser() {
                dismiss()
            }
        } catch {
            // Ignore errors; stay on this screen
        }
    }

    // MARK: - Helpers
    private func redirectURLString() -> String {
        return RedirectManager.makeLink(path: "reset-password")?.absoluteString ?? ""
    }

    private func isValidEmail(_ email: String) -> Bool {
        // Simple validation, adequate for UI enable/disable
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private var resetPasswordHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Reset Your Password")
                .font(.title2).bold()
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Email address")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                TextField("name@example.com", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    private var sendResetEmailButton: some View {
        Button(action: { Task { await handleSubmit() } }) {
            HStack {
                if isLoading { ProgressView() }
                Text(isLoading ? "Sending…" : "Send Reset Email")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading || !isValidEmail(email))
        .padding(.top, 8)
    }
    
    private var toastView: some View {
        Group {
            if showToast {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: toastType == .success ? "checkmark.circle.fill" : (toastType == .error ? "xmark.octagon.fill" : "hourglass"))
                            .imageScale(.large)
                        Text(toastMessage)
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.25), value: showToast)
                .onAppear {
                    // Auto-hide after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        withAnimation { showToast = false }
                    }
                }
            }
        }
    }
}

// You can unify this with your existing StatusType if present elsewhere
enum ForgotPasswordStatusType {
    case none
    case loading
    case success
    case error
}

    
