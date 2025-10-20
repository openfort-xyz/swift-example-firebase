//
//  WalletConnectPanelView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-05.
//

import SwiftUI
import Foundation
import Combine

struct WalletConnectPanelView: View {
    @ObservedObject var viewModel: WalletConnectPanelViewModel
    
    @State private var pairingCode: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wallet Connect")
                .font(.headline)
            
            TextField("Pairing Code", text: $pairingCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 4)
            
            Button(action: {
                Task {
                    isLoading = true
                    await viewModel.setPairingCode(pairingCode: pairingCode)
                    pairingCode = ""
                    isLoading = false
                }
            }) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Pair with dApp")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || pairingCode.isEmpty)
            
            if !viewModel.activeSessions.isEmpty {
                ForEach(viewModel.activeSessions, id: \.self) { session in
                    HStack {
                        Text(session.peerName)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Button("Disconnect") {
                            Task { await viewModel.disconnectSession(session) }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .cornerRadius(6)
                    }
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            } else {
                Text("No dApps are connected yet.")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

class WalletConnectPanelViewModel: ObservableObject {
    @Published var activeSessions: [WalletConnectSession] = []
    
    // Example session model
    struct WalletConnectSession: Hashable {
        let id: String
        let peerName: String
    }
    
    // Async connect
    func setPairingCode(pairingCode: String) async {
        // Call your WalletConnect SDK to connect and listen for events.
        // On new session, update activeSessions
        // Example: self.activeSessions = fetchedSessions
    }
    
    // Async disconnect
    func disconnectSession(_ session: WalletConnectSession) async {
        // Call your WalletConnect SDK to disconnect
        // Remove from activeSessions on success
        // Example: self.activeSessions.removeAll { $0.id == session.id }
    }
}
