//
//  ConnectWalletView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-08.
//

import SwiftUI
import OpenfortSwift

// MARK: - Placeholder types
enum ConnectWalletStatusType: Identifiable {
    case success(String)
    case error(String)
    var id: String {
        switch self {
        case .success(let msg): return "success:\(msg)"
        case .error(let msg): return "error:\(msg)"
        }
    }
}

// Replace with your actual user type
struct AuthPlayerResponse: Codable {
    let id: String
    let email: String?
}

// MARK: - Main View
struct ConnectWalletView: View {
    var onSignIn: (() -> Void)?
    @State private var user: AuthPlayerResponse? = nil
    @State private var status: ConnectWalletStatusType? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 32)
                    VStack(spacing: 24) {
                        Text("Continue with your wallet")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        WalletConnectButtonsSection(onSuccess: {
                            
                        }, link: false)

                        HStack {
                            Text("Have an account?")
                                .font(.subheadline)
                            Button(action: {
                                onSignIn?()
                                dismiss()
                            }) {
                                Text("Sign in")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                            Spacer()
                        }
                        .padding(.top, 10)
                    }
                    .padding(30)
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(radius: 12)
                    .padding(.horizontal)

                    Spacer()
                }

                if let status = status {
                    ToastView(status: status) {
                        self.status = nil
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear(perform: fetchUser)
    }

    // MARK: - Actions
    private func fetchUser() {
        // TODO: Replace with your actual fetch user logic
        // Simulate fetching user:
        Task {
            await MainActor.run {
                // self.user = try? await openfortUserGet()
            }
        }
    }

    private func handleSuccess() {
        // Redirect: In SwiftUI, this could be a dismiss, or pop to root, etc.
        presentationMode.wrappedValue.dismiss()
    }

    private func setStatus(_ status: ConnectWalletStatusType?) {
        withAnimation {
            self.status = status
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let status: ConnectWalletStatusType
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                Text(statusText)
                    .foregroundColor(statusColor)
                    .bold()
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .padding(.horizontal)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding()
        }
        .animation(.easeInOut, value: status.id)
    }

    private var statusIcon: String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
    private var statusColor: Color {
        switch status {
        case .success: return .green
        case .error: return .red
        }
    }
    private var statusText: String {
        switch status {
        case .success(let message): return message
        case .error(let message): return message
        }
    }
}

#Preview {
    ConnectWalletView()
}
