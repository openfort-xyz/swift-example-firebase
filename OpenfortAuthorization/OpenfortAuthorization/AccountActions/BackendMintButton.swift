//
//  BackendMintButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift
import Web3

struct BackendMintButton: View {
    let handleSetMessage: (String) -> Void

    // TODO: Provide a secure session/private key for signing (e.g., session key)
    // Store/fetch this securely (Keychain/Protected storage). This is just a placeholder.
    private let sessionPrivateKeyHex: String? = nil // e.g. "0xabc123..."

    @State private var isLoading: Bool = false
    @State private var stateIsReady: Bool = true // Set from your environment/model

    // MARK: - Helpers (Hex/Data and signing)
    private func dataFromHex(_ hex: String) async -> Data? {
        var hexString = hex.lowercased()
        if hexString.hasPrefix("0x") { hexString.removeFirst(2) }
        guard hexString.count % 2 == 0 else { return nil }
        var data = Data(); data.reserveCapacity(hexString.count/2)
        var index = hexString.startIndex
        while index < hexString.endIndex {
            let next = hexString.index(index, offsetBy: 2)
            let byteString = hexString[index..<next]
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        return data
    }

    /// Signs a 32-byte userOperationHash (already keccak256) with Web3.swift and
    /// returns a 65-byte ECDSA signature hex string 0x{r}{s}{v}.
    private func signUserOpHashWithWeb3(hashHex: String, privateKeyHex: String) throws -> String {
        // Parse 0x… hex into raw 32 bytes
        func dataFromHex(_ hex: String) -> Data? {
            var s = hex.lowercased()
            if s.hasPrefix("0x") { s.removeFirst(2) }
            guard s.count % 2 == 0 else { return nil }
            var out = Data(); out.reserveCapacity(s.count / 2)
            var i = s.startIndex
            while i < s.endIndex {
                let j = s.index(i, offsetBy: 2)
                guard let b = UInt8(s[i..<j], radix: 16) else { return nil }
                out.append(b)
                i = j
            }
            return out
        }

        func leftPad(_ data: Data, to size: Int) -> Data {
            if data.count >= size { return data }
            return Data(repeating: 0, count: size - data.count) + data
        }

        guard let hashData = dataFromHex(hashHex), hashData.count == 32 else {
            throw NSError(domain: "OF.Sign", code: -10,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid 32-byte hash"])
        }

        // 1) Private key
        let pk = try EthereumPrivateKey(hexPrivateKey: privateKeyHex)

        // 2) Sign raw digest -> expects [UInt8]
        let sig = try pk.sign(hash: Array(hashData))  // <-- fix: pass [UInt8], not EthereumData

        // 3) Serialize r, s (32 bytes each), v (27/28)
        let rData = leftPad(Data(sig.r), to: 32)
        let sData = leftPad(Data(sig.s), to: 32)

        // Normalize v to 27/28 if library returns 0/1
        let vAdj: UInt8 = (sig.v == 27 || sig.v == 28) ? UInt8(sig.v) : UInt8(sig.v + 27)

        var out = Data(capacity: 65)
        out.append(rData)
        out.append(sData)
        out.append(vAdj)

        return "0x" + out.map { String(format: "%02x", $0) }.joined()
    }

    var body: some View {
        Button(action: {
            Task {
                isLoading = true
                let transactionHash = await mintNFT()
                isLoading = false
                if let txHash = transactionHash {
                    handleSetMessage("https://amoy.polygonscan.com/tx/\(txHash)")
                }
            }
        }) {
            if isLoading {
                ProgressView()
            } else {
                Text("Mint NFT")
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.bordered)
        .disabled(!stateIsReady || isLoading)
    }

    func mintNFT() async -> String? {
        do {
            let accessToken = try await OFSDK.shared.getAccessToken()
            guard let url = URL(string: "https://yourdomain.com/api/mint") else { return nil }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken ?? "")", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Handle error
                print("Failed to mint NFT. Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return nil
            }

            // Parse JSON for transactionIntentId and userOperationHash
            let collectResponse = try JSONDecoder().decode(CollectResponse.self, from: data)

            // Sign the userOperationHash locally using Web3 (session key)
            guard let pkHex = sessionPrivateKeyHex, !pkHex.isEmpty else {
                print("Missing session private key for Web3 signing")
                return nil
            }
            let signature = try signUserOpHashWithWeb3(hashHex: collectResponse.userOperationHash, privateKeyHex: pkHex)

            let params = OFSendSignatureTransactionIntentRequestParams(
                transactionIntentId: collectResponse.transactionIntentId,
                signableHash: collectResponse.userOperationHash, // include for traceability
                signature: signature,
                optimistic: false
            )
            let transactionHash = try await OFSDK.shared.sendSignatureTransactionIntentRequest(params: params)?.response?.transactionHash

            return transactionHash
        } catch {
            print("Mint NFT error: \(error)")
            return nil
        }
    }

    struct CollectResponse: Decodable {
        let transactionIntentId: String
        let userOperationHash: String
    }
}

private func + (lhs: Data, rhs: Data) -> Data {
    var d = Data(); d.reserveCapacity(lhs.count + rhs.count)
    d.append(lhs); d.append(rhs)
    return d
}
