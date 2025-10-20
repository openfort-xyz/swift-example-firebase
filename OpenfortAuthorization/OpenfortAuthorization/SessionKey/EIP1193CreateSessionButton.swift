//
//  EIP1193CreateSessionButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift
import Web3
import Web3ContractABI
import Web3PromiseKit

struct EIP1193CreateSessionButton: View {
    let handleSetMessage: (String) -> Void
    var setSessionKey: (String?) -> Void
    var openfort = OFSDK.shared
    
    @Binding var sessionKey: String? // 0x-prefixed hex string
    @State private var loading = false
    
    var body: some View {
        VStack {
            Button(action: {
                Task { await handleCreateSession() }
            }) {
                if loading {
                    ProgressView()
                } else {
                    Text("Create session")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(openfort.embeddedState != OFEmbeddedState.ready || sessionKey != nil)
            .buttonStyle(.bordered)
            
            BackendMintButton(
                handleSetMessage: handleSetMessage
            )
        }
    }
    
    func handleCreateSession() async {
        loading = true
        do {
            guard let provider = try await openfort.getEthereumProvider(params: OFGetEthereumProviderParams()) else {
                return
            }
            
            let tx: [String: String] = [
                "to": "0x4B0897b0513FdBeEc7C469D9aF4fA6C0752aBea7",
                "from": "0xDeaDbeefdEAdbeefdEadbEEFdeadbeefDEADbEEF",
                "gas": "0x76c0", // 30400 in hex
                "value": "0x8ac7230489e80000", // 10 ETH in wei hex
                "data": "0x",
                "gasPrice": "0x4a817c800" // 20 gwei
            ]

            let request = RPCRequest<[ [String: String] ]>(
                id: 0,
                jsonrpc: "",
                method: "eth_sendTransaction",
                params: [tx]   // array of transaction objects
            )

            provider.send(request: request) { (resp: Web3Response<String>) in
                if let chainIdHex: String = resp.result {
                    let chainIdDec = Int(chainIdHex.dropFirst(2), radix: 16) ?? -1
                    print("chainId (hex): \(chainIdHex), (dec): \(chainIdDec)")
                }
            }
        } catch {
            
        }
       
        /*defer { loading = false }
        do {
            guard let provider = try await openfort.getEthereumProvider(params: OFGetEthereumProviderParams(policy: "", chains: [80001: "https://rpc-amoy.polygon.technology"])) else {
                handleSetMessage("Failed to get Ethereum provider")
                return
            }
            // 1) Generate the new session keypair
            let newPrivateKey = generatePrivateKey()
            let sessionAddress = privateKeyToAddress(newPrivateKey)

            // 2) Create a signer from the private key (Boilertalk Web3.swift)
            let pkNo0x = newPrivateKey.hasPrefix("0x") ? String(newPrivateKey.dropFirst(2)) : newPrivateKey
            let pkData = Data(hex: pkNo0x)
                
            let privateKey = try EthereumPrivateKey(privateKey: pkData)
            let sessionAddressEth = privateKey.address

            // 3) Create a Web3 instance using the provider
            var web3 = Web3(provider: provider)

            // ABI for grantPermissions
            let grantAbiJson = """
            [
              {
                "inputs": [
                  {"name": "signer", "type": "address"},
                  {"name": "expiry", "type": "uint64"},
                  {"name": "permissions", "type": "bytes"}
                ],
                "name": "grantPermissions",
                "outputs": [],
                "stateMutability": "nonpayable",
                "type": "function"
              }
            ]
            """

            // 4) Build the dynamic contract
            let contract = try web3.eth.Contract(
                json: Data(grantAbiJson.utf8),
                abiKey: nil,
                address: EthereumAddress("0xYourManagerContract")
            )

            // 5) Prepare the function invocation
            let invocation = contract["grantPermissions"]!(
                try EthereumAddress(sessionAddress),
                BigUInt(60 * 60 * 24),
                Data() // put encoded permissions here
            )

            // 6) Create a transaction and sign with the session private key
            firstly {
                web3.eth.getTransactionCount(address: sessionAddressEth, block: EthereumQuantityTag(tagType: .latest))
            }.then { nonce -> Promise<BigUInt> in
                web3.eth.gasPrice().map { quantity in
                    quantity.quantity
                }
            }.then { gasPrice -> Promise<EthereumTransaction> in
                let tx = try invocation.createTransaction(nonce: nonce, gasPrice: gasPrice, maxFeePerGas: nil, maxPriorityFeePerGas: nil, gasLimit: nil, from: sessionAddressEth, value: BigUInt(0), accessList: <#T##OrderedDictionary<EthereumAddress, [EthereumData]>#>, transactionType: .legacy)
            }.then { tx -> Promise<EthereumSignedTransaction> in
                let signed = try tx.sign(with: privateKey, chainId: 80002) // polygonAmoy
                return .value(signed)
            }.then { signed -> Promise<Web3Response<EthereumData>> in
                web3.eth.sendRawTransaction(transaction: signed)
            }.done { resp in
                switch resp.status {
                case .success(let txHash):
                    setSessionKey(newPrivateKey)
                    handleSetMessage("""
                    Session key registered successfully:\nAddress: \(sessionAddress)\nTx: \(txHash.hexString)
                    """)
                case .failure(let err):
                    handleSetMessage("Failed to register session: \(err.localizedDescription)")
                }
            }.catch { error in
                handleSetMessage("Failed to register session: \(error.localizedDescription)")
            }
        } catch {
            handleSetMessage(error.localizedDescription)
            return
        }*/
    }
}

// Dummy implementations for cryptography (use real library in prod!)
func generatePrivateKey() -> String {
    // Use a secure RNG!
    // Example: generate a random 32-byte hex string prefixed with 0x
    let bytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
    return "0x" + bytes.map { String(format: "%02x", $0) }.joined()
}

func privateKeyToAddress(_ privateKey: String) -> String {
    // Use web3 or secp256k1 to get the address from private key
    // Here just a dummy example
    return "0x" + privateKey.dropFirst(4).prefix(40)
}

func grantSessionKeyPermissions(provider: Any, sessionAddress: String, contract: String) async throws -> Bool {
    // Implement your EVM permissions logic here
    // Return true if success, false if not
    // For now, always succeed
    return true
}
