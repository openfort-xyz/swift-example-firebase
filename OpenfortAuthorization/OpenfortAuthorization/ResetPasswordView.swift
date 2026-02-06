//
//  ResetPasswordView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import FirebaseAuth

struct ResetPasswordView: View {
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var error: String?
    @State private var status: Status?

    @Environment(\.dismiss) private var dismiss

    let state: String
    let email: String

    enum StatusType {
        case idle, loading, success, error(String)
    }
    struct Status {
        var type: StatusType
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack {
                Spacer(minLength: 40)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Reset Your Password")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.bottom, 24)

                    VStack(spacing: 24) {
                        VStack(alignment: .leading) {
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
                            .background(Color.white)

                            Text("Your password must be at least 8 characters including a lowercase letter, an uppercase letter, and a special character (e.g. !@#%&*).")
                                .font(.caption)
                                .foregroundColor(error == "invalidPassword" ? .red : .gray)
                                .fontWeight(error == "invalidPassword" ? .medium : .regular)
                                .padding(.top, 4)
                        }
                    }

                    Button(action: {
                        submit()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        } else {
                            Text("Save New Password")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                    .disabled(isLoading)
                    .background(isLoading ? Color.gray.opacity(0.2) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top, 24)

                    HStack {
                        Text("Already have an account?")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        NavigationLink(destination: LoginView()) {
                            Text("Sign in")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                        }
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
            .padding(.top, 20)
            .toast(status: status, setStatus: { status = $0 })
        }
    }

    func submit() {
        isLoading = true
        error = nil
        if !validatePassword(password) {
            error = "invalidPassword"
            isLoading = false
            return
        }

        Task {
            defer { isLoading = false }
            do {
                // state contains the oobCode from the Firebase password reset email
                try await Auth.auth().confirmPasswordReset(withCode: state, newPassword: password)
                status = Status(type: .success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            } catch {
                status = Status(type: .error("Failed to reset password. Please try again."))
            }
        }
    }

    func validatePassword(_ pw: String) -> Bool {
        let lower = pw.range(of: "[a-z]", options: .regularExpression) != nil
        let upper = pw.range(of: "[A-Z]", options: .regularExpression) != nil
        let special = pw.range(of: "[!@#%&*]", options: .regularExpression) != nil
        return pw.count >= 8 && lower && upper && special
    }
}

extension View {
    func toast(status: ResetPasswordView.Status?, setStatus: @escaping (ResetPasswordView.Status?) -> Void) -> some View {
        ZStack {
            self
            if let status = status {
                switch status.type {
                case .success:
                    Text("Password reset successful!")
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { setStatus(nil) } }
                case .error(let message):
                    Text(message)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 2) { setStatus(nil) } }
                default:
                    EmptyView()
                }
            }
        }
    }
}

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView(state: "", email: "")
    }
}
