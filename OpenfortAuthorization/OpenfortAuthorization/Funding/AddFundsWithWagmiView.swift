//
//  AddFundsWithWagmiView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI

struct AddFundsWithWagmiView: View {
    let fundAddress: String
    let fundAmount: String
    let callback: () -> Void

    @State private var isSending: Bool = false
    @State private var sendSuccess: Bool = false
    @State private var selectedWallet: String? = nil

    let wallets: [WalletType] = [
        .metamask,
        .walletConnect,
        .rainbow,
        .coinbase
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose a wallet to send \(fundAmount) ETH to:")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(fundAddress)
                .font(.footnote)
                .foregroundColor(.blue)
                .lineLimit(1)
                .contextMenu {
                    Button("Copy address") {
                        UIPasteboard.general.string = fundAddress
                    }
                }

            ForEach(wallets, id: \.self) { wallet in
                Button(action: {
                    selectedWallet = wallet.name
                    isSending = true
                    // Simulate delay for sending
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isSending = false
                        sendSuccess = true
                        callback()
                    }
                }) {
                    HStack {
                        if isSending && selectedWallet == wallet.name {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: wallet.iconName)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        Text(wallet.displayName)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .disabled(isSending)
            }

            if sendSuccess {
                Text("Funds sent successfully!").foregroundColor(.green)
            }
        }
        .padding()
    }

    enum WalletType: String, CaseIterable {
        case metamask, walletConnect, rainbow, coinbase

        var name: String { self.rawValue }
        var displayName: String {
            switch self {
            case .metamask: return "MetaMask"
            case .walletConnect: return "WalletConnect"
            case .rainbow: return "Rainbow"
            case .coinbase: return "Coinbase"
            }
        }
        var iconName: String {
            switch self {
            case .metamask: return "bolt.circle.fill"
            case .walletConnect: return "link.circle.fill"
            case .rainbow: return "circle.grid.cross.fill"
            case .coinbase: return "c.circle.fill"
            }
        }
    }
}
