//
//  EmbeddedWalletPanelView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-05.
//

import SwiftUI
import OpenfortSwift

struct EmbeddedWalletPanelView: View {
    let handleSetMessage: (String) -> Void
    let viewModel: EmbeddedWalletPanelViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Embedded wallet").font(.headline)
            HStack {
                Text("Export wallet private key: ").fontWeight(.medium)
                Button("Export") {
                    Task {
                        do {
                            let response = try await viewModel.exportPrivateKey()
                            if !response.isEmpty {
                                handleSetMessage("Exported private key: \(response)")
                            }
                        } catch {
                            handleSetMessage("Failed to export private key")
                        }
                    }
                }
            }
            Text("Change wallet recovery:")
            SetWalletRecoveryButton(handleSetMessage: handleSetMessage, viewModel: viewModel)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

class EmbeddedWalletPanelViewModel: ObservableObject {
    @Published var embeddedState: OFEmbeddedState = .none
    @Published var embeddedAccount: OFEmbeddedAccount?
    
    init(embeddedState: OFEmbeddedState, embeddedAccount: OFEmbeddedAccount?) {
        self.embeddedState = embeddedState
        self.embeddedAccount = embeddedAccount
    }
    
    func exportPrivateKey() async throws -> String {
         try await OFSDK.shared.exportPrivateKey() ?? ""
    }
    
    @MainActor
    func setWalletRecovery(method: String, password: String?) async throws {
        do {
            let session = try await getEncryptionSession()
            if embeddedAccount?.recoveryMethod == .password {
                try await OFSDK.shared.setRecoveryMethod(params: OFSetRecoveryMethodParams(previousRecovery: OFRecoveryParamsDTO(recoveryMethod: .password, password: password),  newRecovery: OFRecoveryParamsDTO(recoveryMethod: .automatic, encryptionSession: session)))
            } else {
                try await OFSDK.shared.setRecoveryMethod(params: OFSetRecoveryMethodParams(previousRecovery: OFRecoveryParamsDTO(recoveryMethod: .automatic, encryptionSession: session), newRecovery: OFRecoveryParamsDTO(recoveryMethod: .password, password: password)))
            }
        } catch {
            throw error
        }
    }
}
