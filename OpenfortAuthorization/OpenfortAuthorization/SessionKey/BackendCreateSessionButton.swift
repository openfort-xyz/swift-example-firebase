//
//  BackendCreateSessionButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift

struct BackendCreateSessionButton: View {
    let handleSetMessage: (String) -> Void
    let setSessionKey: (String?) -> Void
    let sessionKey: String?
    let openfort = OFSDK.shared // Your app’s state/logic object

    @State private var loading: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    if sessionKey != nil {
                        await handleRevokeSession()
                    } else {
                        await handleCreateSession()
                    }
                }
            }) {
                if loading {
                    ProgressView()
                } else if sessionKey != nil {
                    Text("Revoke session")
                } else {
                    Text("Create session")
                }
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
            .disabled(openfort.embeddedState != .ready)

            BackendMintButton(
                handleSetMessage: handleSetMessage
            )
        }
    }

    func handleCreateSession() async {
        loading = true
        defer { loading = false }
        do {
            let token = try await openfort.getAccessToken()
            let newSessionKey = generatePrivateKey() // Implement this for real use!
//            let accountSession = privateKeyToAccount(newSessionKey) // Implement this
//
//            // Select session duration (update as per your radio selection UI)
//            let sessionDuration = "1day"
//
//            // Simulate fetch to `/api/protected-create-session`
//            let sessionResponse = try await openfort.createSessionRequest(
//                token: token,
//                sessionDuration: sessionDuration,
//                sessionAddress: accountSession.address
//            )
//
//            if let nextAction = sessionResponse.data?.nextAction,
//               let hash = nextAction.payload?.userOperationHash {
//                let signature = try await openfort.signMessage(params: OFSignMessageParams(message: hash, options:OFSignMessageParams.Options(hashMessage: true, arrayifyMessage: true)))
//                guard signature.error == nil, let signedData = signature.data else {
//                    throw NSError(domain: "SignMessage", code: 1, userInfo: [NSLocalizedDescriptionKey: signature.error ?? "Unknown error"])
//                }
//                let response = try await openfort.sendSignatureSessionRequest(params: OFSendSignatureSessionRequestParams(sessionId: sessionResponse.data.id, signature: signedData))
//                guard response.isActive else {
//                    throw NSError(domain: "Session", code: 2, userInfo: [NSLocalizedDescriptionKey: "Session key registration failed"])
//                }
//                setSessionKey(newSessionKey)
//                handleSetMessage("""
//                Session key registered successfully:
//                   Address: \(accountSession.address)
//                   Private Key: \(newSessionKey)
//                """)
//            }
        } catch {
            handleSetMessage("Failed to create session: \(error.localizedDescription)")
        }
    }

    func handleRevokeSession() async {
        loading = true
        defer { loading = false }
        do {
            guard let sessionKey = sessionKey else {
                handleSetMessage("No session key or access token")
                return
            }
            let token = try await openfort.getAccessToken()
//            let sessionSigner = privateKeyToAccount(sessionKey)
//            let revokeResponse = try await openfort.revokeSessionRequest(
//                token: token,
//                sessionAddress: sessionSigner.address
//            )
//            if let nextAction = revokeResponse.data?.nextAction,
//               let hash = nextAction.payload?.userOperationHash {
//                let signature = try await openfort.signMessage(params: OFSignMessageParams(message: hash, options:OFSignMessageParams.Options(hashMessage: true, arrayifyMessage: true)))
//                let response = try await openfort.sendSignatureSessionRequest(params: OFSendSignatureSessionRequestParams(sessionId: revokeResponse.data.id, signature: signature.data ?? ""))
//                setSessionKey(nil)
//                handleSetMessage("Session key revoked successfully")
//            } else {
//                handleSetMessage("Session key revoked successfully")
//                setSessionKey(nil)
//            }
        } catch {
            handleSetMessage("Failed to revoke session: \(error.localizedDescription)")
        }
    }
}
