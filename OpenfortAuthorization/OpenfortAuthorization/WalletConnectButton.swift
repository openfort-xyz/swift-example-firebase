//
//  WalletConnectButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-08.
//

import SwiftUI
import OpenfortSwift

struct WalletConnectorInfo: Identifiable {
    let id: String
    let name: String
    let iconName: String
    let type: WalletConnector
}

enum WalletConnector: String, CaseIterable, Identifiable {
    case metaMask, coinbase, walletConnect
    var id: String { rawValue }
}

// Dummy icons, replace with your own
let availableWallets: [WalletConnectorInfo] = [
    .init(id: "metamask", name: "MetaMask", iconName: "cube.box", type: .metaMask),
    .init(id: "coinbase", name: "Coinbase", iconName: "wallet.pass", type: .coinbase),
    .init(id: "walletconnect", name: "WalletConnect", iconName: "link", type: .walletConnect)
]

// This would be your main buttons section
struct WalletConnectButtonsSection: View {
    @State private var loadingButtonId: String? = nil
    let onSuccess: () -> Void
    let link: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(availableWallets) { wallet in
                WalletConnectButton(
                    title: wallet.name,
                    isLoading: loadingButtonId == wallet.id,
                    iconName: wallet.iconName,
                    onTap: { connect(wallet: wallet) }
                )
            }
        }
    }

    func connect(wallet: WalletConnectorInfo) {
        loadingButtonId = wallet.id
        Task {
            do {
                let address = wallet.type.rawValue
                let nonce = try await fetchNonce(address: address)
                let siweMessage = createSIWEMessage(address: address, nonce: nonce, chainId: 80001)
                let signature = try await signMessage(siweMessage)
                try await authenticateOrLink(signature: signature, message: siweMessage, wallet: wallet, link: link)
                onSuccess()
            } catch {
                // Show error, e.g. with a toast
            }
            loadingButtonId = nil
        }
    }
}

struct WalletConnectButton: View {
    let title: String
    let isLoading: Bool
    let iconName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: iconName)
                }
                Text(title)
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}

// MARK: - Helper/Network Logic Stubs

func fetchNonce(address: String) async throws -> String {
    let result =  try await OFSDK.shared.initSIWE(params: OFInitSIWEParams(address: address))
    return result?.nonce ?? ""
}

func createSIWEMessage(address: String, nonce: String, chainId: Int) -> String {
    SIWEUtils.createSIWEMessage(address: address, nonce: nonce, chainId: chainId)
}

func signMessage(_ message: String) async throws -> String {
    let result = try await OFSDK.shared.signMessage(params: OFSignMessageParams(message: message))
    return result ?? ""
}

func authenticateOrLink(signature: String, message: String, wallet: WalletConnectorInfo, link: Bool) async throws {
    if link {
        _ = try await OFSDK.shared.linkWallet(params: OFLinkWalletParams(signature: signature, message: message, walletClientType: wallet.name, connectorType: wallet.type.rawValue, authToken: try OFSDK.shared.getAccessToken() ?? ""))
    } else {
        _ = try await OFSDK.shared.authenticateWithSIWE(params: OFAuthenticateWithSIWEParams(signature: signature, message: message, walletClientType: wallet.name, connectorType: wallet.type.rawValue))
    }
}
