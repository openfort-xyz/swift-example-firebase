//
//  SignTypedDataButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-05.
//

import SwiftUI
import OpenfortSwift

struct SignTypedDataButton: View {
    let handleSetMessage: (String) -> Void
    @State var embeddedState: OFEmbeddedState

    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                Task {
                    await handleSignTypedData()
                }
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Sign Typed Message")
                }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .disabled(embeddedState != .ready || isLoading)

            // Link to show the typed message definition
            Link("View typed message",
                 destination: URL(string: "https://github.com/openfort-xyz/swift-example/blob/088645af2090dcbe1642fac14105eb8e33ace39d/OpenfortAuthorization/OpenfortAuthorization/Signatures/SignTypedDataButton.swift#L85")!)
                .font(.caption)
                .foregroundColor(.blue)
        }
    }

    private func handleSignTypedData() async {
        guard embeddedState == .ready else { return }
        isLoading = true
        defer { isLoading = false }

        let domain = EIP712Domain(
            name: "Openfort",
            version: "0.5",
            chainId: 80002,
            verifyingContract: "0x9b5AB198e042fCF795E4a0Fa4269764A4E8037D2"
        )
        let types: [String: [EIP712TypeField]] = [
            "Mail": [
                EIP712TypeField(name: "from", type: "Person"),
                EIP712TypeField(name: "to", type: "Person"),
                EIP712TypeField(name: "content", type: "string")
            ],
            "Person": [
                EIP712TypeField(name: "name", type: "string"),
                EIP712TypeField(name: "wallet", type: "address")
            ]
        ]
        
        let message = EIP712MailMessage(
            from: EIP712PersonMessage(
                name: "Alice",
                wallet: "0x2111111111111111111111111111111111111111"
            ),
            to: EIP712PersonMessage(
                name: "Bob",
                wallet: "0x3111111111111111111111111111111111111111"
            ),
            content: "Hello World!"
        )
        
        do {
            let params = OFSignTypedDataParams(
                domain: domain,
                types: types,
                message: message
            )

            let result = try await OFSDK.shared.signTypedData(params: params)
            handleSetMessage(result ?? "Signed!")
        } catch {
            print("Failed to sign typed message:", error)
            handleSetMessage("Failed to sign typed message: \(error.localizedDescription)")
        }
    }
}
