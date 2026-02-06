//
//  ForgotPasswordView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-12.
//

import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    // MARK: - State
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastType: ForgotPasswordStatusType = .none
    @State private var showToast: Bool = false
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    // MARK: - Actions
    private func handleSubmit() async {
        guard !email.isEmpty else { return }
        isLoading = true
        showToast = false

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            toastMessage = "Successfully sent email"
            toastType = .success
            showToast = true
        } catch {
            toastMessage = "Error sending email: \(error.localizedDescription)"
            toastType = .error
            showToast = true
        }
        isLoading = false
    }

    // MARK: - Helpers
    private func isValidEmail(_ email: String) -> Bool {
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
                Text(isLoading ? "Sending..." : "Send Reset Email")
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                        withAnimation { showToast = false }
                    }
                }
            }
        }
    }
}

enum ForgotPasswordStatusType {
    case none
    case loading
    case success
    case error
}
