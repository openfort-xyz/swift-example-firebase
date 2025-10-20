//
//  SetWalletRecoveryButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-05.
//

import SwiftUI

struct SetWalletRecoveryButton: View {
    enum RecoveryMethod: String {
        case automatic = "automatic"
        case password = "password"
    }
    let handleSetMessage: (String) -> Void
    
    @ObservedObject var viewModel: EmbeddedWalletPanelViewModel
    @State private var loading: RecoveryMethod?
    @State private var automaticPassword: String = ""
    @State private var passwordPassword: String = ""

    var body: some View {
        VStack(spacing: 16) {
            // Automatic Recovery
            TextField("Old password recovery", text: $automaticPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)

            Button(action: {
                Task {
                    await handleSetWalletRecovery(.automatic)
                }
            }) {
                if loading == .automatic {
                    ProgressView()
                } else {
                    Text("Set Automatic Recovery")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.embeddedState != .ready || loading != nil)

            // Or separator
            HStack {
                Spacer()
                Text("- or -").foregroundColor(.gray)
                Spacer()
            }

            // Password Recovery
            TextField("New password recovery", text: $passwordPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)

            Button(action: {
                Task {
                    await handleSetWalletRecovery(.password)
                }
            }) {
                if loading == .password {
                    ProgressView()
                } else {
                    Text("Set Password Recovery")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.embeddedState != .ready || loading != nil)
        }
        .padding()
    }

    private func handleSetWalletRecovery(_ recoveryMethod: RecoveryMethod) async {
        do {
            loading = recoveryMethod
            let password = recoveryMethod == .automatic ? automaticPassword : passwordPassword
            try await viewModel.setWalletRecovery(method: recoveryMethod.rawValue, password: password)
            handleSetMessage("Set \(recoveryMethod.rawValue) wallet recovery successful")
            loading = nil
        } catch {
            print("Failed to update recovery method: \(error)")
            handleSetMessage("Failed to update recovery method. Please try again.")
            loading = nil
        }
    }
}
