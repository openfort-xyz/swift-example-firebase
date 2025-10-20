//
//  SignMessageButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-05.
//

import SwiftUI
import OpenfortSwift

struct SignMessageButton: View {
    let handleSetMessage: (String) -> Void
    @State var embeddedState: OFEmbeddedState 

    @State private var isLoading = false

    var body: some View {
        Button(action: {
            Task {
                await handleSignMessage()
            }
        }) {
            if isLoading {
                ProgressView()
            } else {
                Text("Sign Message")
            }
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
        .disabled(embeddedState != .ready || isLoading)
    }

    private func handleSignMessage() async {
        guard embeddedState == .ready else { return }
        do {
            isLoading = true
            let result = try await OFSDK.shared.signMessage(params: OFSignMessageParams(message: "Hello!"))
            isLoading = false
            handleSetMessage(result ?? "Signed!")
        } catch {
            isLoading = false
            handleSetMessage("Failed to sign message:\(error.localizedDescription)")
            print("Failed to sign message:", error)
            // Show your error handling here, like a toast or alert
        }
    }
}
