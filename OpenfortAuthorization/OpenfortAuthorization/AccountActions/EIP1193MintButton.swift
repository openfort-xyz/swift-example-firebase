//
//  EIP1193MintButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift
import Web3
import Web3ContractABI

struct EIP1193MintButton: View {
    let handleSetMessage: (String) -> Void

    @State private var loading: Bool = false
    @State private var loadingBatch: Bool = false
    let openfort: OFSDK

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                Task { await handleSendTransaction() }
            }) {
                if loading {
                    ProgressView()
                } else {
                    Text("Mint NFT")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(openfort.embeddedState != .ready || loading)
            .buttonStyle(.bordered)

            Button(action: {
                Task { await handleSendCalls() }
            }) {
                if loadingBatch {
                    ProgressView()
                } else {
                    Text("Send batch calls")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(openfort.embeddedState != .ready || loadingBatch)
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Contract Interaction
    func handleSendTransaction() async {
        loading = true
        defer { loading = false }
        do {
            do {
                guard let provider = try await openfort.getEthereumProvider(params: OFGetEthereumProviderParams()) else {
                    return
                }
                let web3 = Web3(provider: provider)

                let erc721Address = "0x2522f4fc9af2e1954a3d13f7a5b2683a00a4543a"
                let contractAddress = try EthereumAddress(hex: erc721Address, eip55: false)
                let abi: [String: Any] = [
                    "inputs": [
                        [
                            "internalType": "address",
                            "name": "_to",
                            "type": "address"
                        ]
                    ],
                    "name": "mint",
                    "outputs": [],
                    "stateMutability": "nonpayable",
                    "type": "function"
                ]
                guard let contractJsonABI = try? JSONSerialization.data(withJSONObject: [abi], options: [.prettyPrinted]) else {
                    print("Failed to encode ABI to JSON string")
                    return
                }
                
                let contract = try web3.eth.Contract(json: contractJsonABI, abiKey: nil, address: contractAddress)

                print(contract.methods.count)
                let recipient = "0x64452Dff1180b21dc50033e1680bB64CDd492582"

                let myPrivateKey = try EthereumPrivateKey(hexPrivateKey: "...")
                guard let transaction = contract["transfer"]?(try EthereumAddress(hex: recipient, eip55: false), BigUInt(100000)).createTransaction(
                    nonce: 0,
                    gasPrice: EthereumQuantity(quantity: 21.gwei),
                    maxFeePerGas: nil,
                    maxPriorityFeePerGas: nil,
                    gasLimit: 150000,
                    from: myPrivateKey.address,
                    value: 0,
                    accessList: [:],
                    transactionType: .legacy
                ) else {
                    return
                }
                let signedTx = try transaction.sign(with: myPrivateKey)

                do {
                    try web3.eth.sendRawTransaction(transaction: signedTx) { resp in
                        switch resp.status {
                            case .success(let data):
                                let txHash = data.hex() // EthereumData → hex string
                                print("Transaction sent: \(txHash)")
                                handleSetMessage("https://amoy.polygonscan.com/tx/\(txHash)")
                            case .failure(let error):
                                print("Error sending transaction: \(error)")
                                handleSetMessage("Failed to send transaction: \(error.localizedDescription)")
                            }
                    }

                } catch {
                    print(error)
                    handleSetMessage("Failed to send transaction: \(error.localizedDescription)")
                }
            } catch  {
                handleSetMessage("Failed to get EVM provider")
                return
            }
        }
    }

    func handleSendCalls() async {
        loadingBatch = true
        defer { loadingBatch = false }
        do {
            do {
                let provider = try await openfort.getEthereumProvider(params: OFGetEthereumProviderParams())
                try await openfort.sendSignatureTransactionIntentRequest(params: OFSendSignatureTransactionIntentRequestParams(transactionIntentId: "", signableHash: ""))
            } catch {
                handleSetMessage("Failed to get EVM provider")
                return
            }
            
            let erc721Address = "0x2522f4fc9af2e1954a3d13f7a5b2683a00a4543a"
            let recipient = "0x64452Dff1180b21dc50033e1680bB64CDd492582"
            // TODO: Build and send batch calls using your EVM SDK
            // If success:
            let txHash = "0xEXAMPLETXHASHBATCH"
            handleSetMessage("https://amoy.polygonscan.com/tx/\(txHash)")
        }
    }
}
