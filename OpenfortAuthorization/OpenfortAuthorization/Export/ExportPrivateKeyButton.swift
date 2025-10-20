//
//  ExportPrivateKeyButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-05.
//

import SwiftUI

struct ExportPrivateKeyButton: View {
    @ObservedObject var viewModel: EmbeddedWalletPanelViewModel
    let handleSetMessage: (String) -> Void
    @State private var isLoading = false

    var body: some View {
        Button(action: {
            Task {
                do {
                    isLoading = true
                    let privateKey = try await viewModel.exportPrivateKey()
                    isLoading = false
                    handleSetMessage(privateKey)
                } catch {
                    isLoading = false
                    handleSetMessage("Failed to export private key: \(error.localizedDescription)")
                }
            }
        }) {
            if isLoading {
                ProgressView()
            } else {
                Text("Export key")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.embeddedState != .ready || isLoading)
    }
}


