//
//  WalletListView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-14.
//

import SwiftUI
import OpenfortSwift

// MARK: - Models

public struct WalletWithChainIds: Identifiable, Hashable {
    public let id: String
    public let address: String
    public let accountType: String
    public let chainType: String
    public let implementationType: String?
    public var chainIds: [Int]

    init(from wallet: OFEmbeddedAccount) {
        self.id = wallet.id
        self.address = wallet.address
        self.accountType = wallet.accountType
        self.chainType = wallet.chainType
        self.implementationType = wallet.implementationType
        self.chainIds = wallet.chainId.map { [$0] } ?? []
    }
}

// MARK: - Service protocol (plug your bridge here)

public protocol EmbeddedWalletService {
    /// Returns the raw list of embedded accounts (possibly multiple entries for the same address on different chains).
    func list() async throws -> OFListResponse?

    /// Creates an embedded signer/wallet for the given chain.
    func createEmbeddedSigner(chainId: Int) async throws -> OFEmbeddedAccount?

    /// Recovers/activates a wallet by its server ID for a given chain.
    func recoverEmbeddedSigner(walletId: String, chainId: Int) async throws -> OFEmbeddedAccount?
}

// MARK: - ViewModel

@MainActor
final class WalletListViewModel: ObservableObject {
    @Published var wallets: [WalletWithChainIds] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var isCreating = false
    @Published var isRecovering: String? // walletId currently recovering
    @Published var hasLoadedOnce = false

    let service: EmbeddedWalletService
    let chainId: Int
    let activeAddress: String?

    init(service: EmbeddedWalletService, chainId: Int, activeAddress: String?) {
        self.service = service
        self.chainId = chainId
        self.activeAddress = activeAddress
    }

    func loadWallets(visible: Bool) async {
        guard visible else { return }
        isLoading = true
        error = nil
        defer { isLoading = false; hasLoadedOnce = true }

        do {
            guard let walletsResponse = try await service.list() else {
                return
            }
            // Filter only SMART_ACCOUNT like in TS
            let smartWallets = walletsResponse.filter { $0.accountType.uppercased() == "SMART_ACCOUNT" }

            // Group by address (case-insensitive) and merge chainIds
            var map = [String: WalletWithChainIds]()  // key = lowercased address
            for w in smartWallets {
                let key = w.address.lowercased()
                if var existing = map[key] {
                    if let cid = w.chainId, existing.chainIds.contains(cid) == false {
                        existing.chainIds.append(cid)
                        map[key] = existing
                    }
                } else {
                    map[key] = WalletWithChainIds(from: w)
                }
            }

            wallets = Array(map.values)
                .sorted { $0.address.lowercased() < $1.address.lowercased() }
        } catch {
            self.error = (error as NSError).localizedDescription
            self.wallets = []
        }
    }

    func maybeAutoCreateIfEmpty(visible: Bool) async {
        guard hasLoadedOnce, visible, wallets.isEmpty, !isLoading, !isCreating else { return }
        await createWallet()
        await loadWallets(visible: visible)
    }

    func createWallet() async {
        isCreating = true
        error = nil
        defer { isCreating = false }
        do {
            try await service.createEmbeddedSigner(chainId: chainId)
        } catch {
            self.error = (error as NSError).localizedDescription
        }
    }

    func recoverWallet(id: String) async {
        isRecovering = id
        error = nil
        defer { isRecovering = nil }
        do {
            try await service.recoverEmbeddedSigner(walletId: id, chainId: chainId)
        } catch {
            self.error = (error as NSError).localizedDescription
        }
    }

    func isActive(_ wallet: WalletWithChainIds) -> Bool {
        guard let active = activeAddress else { return false }
        return active.lowercased() == wallet.address.lowercased()
    }
}

// MARK: - View

public struct WalletListView: View {
    public let isVisible: Bool
    @StateObject private var vm: WalletListViewModel

    public init(
        isVisible: Bool,
        service: EmbeddedWalletService,
        chainId: Int,
        activeAddress: String?
    ) {
        self.isVisible = isVisible
        _vm = StateObject(wrappedValue: WalletListViewModel(
            service: service,
            chainId: chainId,
            activeAddress: activeAddress
        ))
    }

    public var body: some View {
        Group {
            if !isVisible {
                EmptyView()
            } else {
                content
            }
        }
        .task {
            await vm.loadWallets(visible: isVisible)
            await vm.maybeAutoCreateIfEmpty(visible: isVisible)
        }
        .onChange(of: isVisible) { newValue in
            Task {
                await vm.loadWallets(visible: newValue)
                await vm.maybeAutoCreateIfEmpty(visible: newValue)
            }
        }
        .navigationTitle("Embedded Wallets")
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            if vm.isLoading {
                Text("Loading wallets…")
                    .foregroundStyle(.secondary)
            }

            if let error = vm.error {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
            }

            if !vm.isLoading, vm.wallets.isEmpty, vm.error == nil {
                Text(vm.isCreating ? "Creating your first wallet…" : "No wallets found. Create your first wallet below.")
                    .foregroundStyle(.secondary)
            }

            if !vm.wallets.isEmpty {
                VStack(spacing: 10) {
                    ForEach(vm.wallets) { wallet in
                        walletRow(wallet)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                }
            }

            Button {
                Task {
                    await vm.createWallet()
                    await vm.loadWallets(visible: isVisible)
                }
            } label: {
                Text(vm.isCreating ? "Creating…" : "Create New Wallet")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isCreating || vm.isRecovering != nil)
        }
        .padding()
    }

    @ViewBuilder
    private func walletRow(_ wallet: WalletWithChainIds) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(wallet.address)
                        .font(.system(.subheadline, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if vm.isActive(wallet) {
                        Text("Active")
                            .font(.caption2).bold()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Text("\(wallet.implementationType ?? "—") • \(wallet.chainType) • Chain IDs: \(wallet.chainIds.isEmpty ? "N/A" : wallet.chainIds.map(String.init).joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !vm.isActive(wallet) {
                Button {
                    Task {
                        await vm.recoverWallet(id: wallet.id)
                        // (Optionally) refresh list after recover
                        await vm.loadWallets(visible: isVisible)
                    }
                } label: {
                    Text(vm.isRecovering == wallet.id ? "Recovering…" : "Recover")
                }
                .buttonStyle(.bordered)
                .disabled(vm.isRecovering == wallet.id || vm.isCreating)
            }
        }
    }
}

struct OpenfortEmbeddedService: EmbeddedWalletService {
    func list() async throws -> OFListResponse? {
        try await OFSDK.shared.list()
    }

    func createEmbeddedSigner(chainId: Int) async throws -> OFEmbeddedAccount? {
        try await OFSDK.shared.create(params: OFEmbeddedAccountCreateParams(accountType: .smartAccount, chainType: .evm, chainId: chainId, recoveryParams: OFRecoveryParamsDTO(recoveryMethod: .automatic, encryptionSession: nil, password: nil, passkeyInfo: nil)))
    }

    func recoverEmbeddedSigner(walletId: String, chainId: Int) async throws -> OFEmbeddedAccount? {
        try await OFSDK.shared.recover(params: OFEmbeddedAccountRecoverParams(account: walletId, recoveryParams: OFRecoveryParamsDTO(recoveryMethod: .automatic, encryptionSession: nil, password: nil, passkeyInfo: nil)))
    }
}
