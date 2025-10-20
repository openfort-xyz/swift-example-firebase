//
//  HomeView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift
import Combine
import FirebaseAuth

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack {
                        if viewModel.state == .embeddedSignerNotConfigured {
                            VStack(spacing: 18) {
                                Text("Set up your embedded signer")
                                    .font(.title2).bold()
                                Text("Welcome, \(viewModel.user?.player?.name ?? viewModel.user?.id ?? "User")!")
                                    .foregroundColor(.gray)
                                // Logout
                                HStack {
                                    Spacer()
                                    Button(role: .destructive) {
                                        Task {
                                            await logout()
                                        }
                                    } label: {
                                        Label("Logout", systemImage: "arrow.right.square")
                                    }
                                    .tint(.red)
                                }
                                // Account recovery component slot
                                AccountRecoveryView(handleRecovery: viewModel.handleRecovery)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 8)
                            .padding(.vertical, 24)
                        } else if viewModel.state == .creatingAccount {
                            VStack {
                                ProgressView()
                                if viewModel.state == .creatingAccount {
                                    Text("Creating your account, please wait...")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.top, 80)
                        } else if viewModel.state == .ready {
                            VStack(alignment: .leading, spacing: 18) {
                                Text("Welcome, \(viewModel.user?.id ?? "user")!")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Button(role: .destructive) {
                                    Task {
                                        await logout()
                                    }
                                } label: {
                                    Label("Logout", systemImage: "arrow.right.square")
                                }
                                .tint(.red)
                                VStack(spacing: 20) {
                                    // Account actions
                                    AccountActionsView(handleSetMessage: viewModel.handleSetMessage)
                                    
                                    // Signatures
                                    SignaturesPanelView(handleSetMessage: viewModel.handleSetMessage, embeddedState: viewModel.state)
                                    
                                    // Linked socials
                                    LinkedSocialsPanelView(user: viewModel.user, handleSetMessage: viewModel.handleSetMessage)
                                    
                                    // Embedded wallet
                                    EmbeddedWalletPanelView(handleSetMessage: viewModel.handleSetMessage)
                                    
                                    // Wallet Connect
                                    WalletConnectPanelView(viewModel: WalletConnectPanelViewModel())
                                    
                                    // Funding
                                    FundingPanelView(handleSetMessage: viewModel.handleSetMessage)
                                }
                                .padding(.top, 12)
                            }
                            .padding()
                        }
                        Spacer()
                    }
                    .frame(maxWidth: 800)
                    .padding(.horizontal, 20)
                }
                
                if viewModel.state != .ready {
                    SidebarIntroView(openDocs: openDocs, openDocsLearnMore: openDocsLearnMore)
                        .background(Color(.systemGray6))
                } else {
                    // Console style sidebar
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Image(systemName: "wallet.pass") // SF Symbol for wallet
                                .font(.system(size: 18))
                            Text("Console").bold()
                            Spacer()
                        }
                        .padding(8)
                        ZStack {
                            TextEditor(text: $viewModel.message)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.black)
                                .background(Color.gray.opacity(0.12))
                                .cornerRadius(6)
                                .padding(8)
                                .frame(minHeight: 140)
                        }
                    }
                    .background(Color(.systemGray6))
                }
            }
            .toast(isPresented: $showToast, message: toastMessage)
            
        }
    }
    
    func openDocs() {
        if let url = URL(string: "https://www.openfort.io/docs") {
            UIApplication.shared.open(url)
        }
    }
    func openDocsLearnMore() {
        if let url = URL(string: "https://www.openfort.io/docs/products/embedded-wallet/react/kit/create-react-app") {
            UIApplication.shared.open(url)
        }
    }
    
    func logout() async {
        await viewModel.logout()
    }
}

struct SidebarIntroView: View {
    let openDocs: () -> Void
    let openDocsLearnMore: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("Explore Openfort")
                    .font(.headline)
                Text("Sign in to the demo to access the dev tools.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Button(action: openDocs) {
                    Text("Explore the Docs")
                }
                .buttonStyle(.bordered)
                .padding(.top, 2)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.orange, lineWidth: 2))
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("Openfort gives you modular components so you can customize your product for your users.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Button(action: openDocsLearnMore) {
                    Text("Learn more")
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

// MARK: - Models & Toast

@MainActor
class HomeViewModel: ObservableObject {
    @Published var state: OFEmbeddedState = .none
    @Published var user: OFGetUserInstanceResponse?
    @Published var message: String = ""
    var onLogout: (() -> Void)?
    
    private var cancellable: AnyCancellable?
    
    lazy var handleRecovery: (_ method: RecoveryMethod, _ password: String?) async throws -> Void = { method, password in
        print("[HomeViewModel] handleRecovery called with method: \(method)")

        let chainId = 80002

        do {
            if method == .password {
                print("[HomeViewModel] Using password recovery method")
                print("[HomeViewModel] Password provided: \(password != nil ? "YES" : "NO")")
                print("[HomeViewModel] Password empty: \(password?.isEmpty ?? true ? "YES" : "NO")")

                let recoveryParams = OFRecoveryParamsDTO(recoveryMethod: .password, encryptionSession: nil, password: password, passkeyInfo: nil)
                print("[HomeViewModel] Calling OFSDK.shared.configure...")
                let result = try await OFSDK.shared.configure(params: OFConfigureEmbeddedWalletDTO(chainId: chainId, recoveryParams: recoveryParams))
                print("[HomeViewModel] Configure succeeded! Result: \(String(describing: result))")
                self.message = "Embedded wallet configured successfully with password recovery.\n\n" + self.message
            } else {
                print("[HomeViewModel] Using automatic recovery method")
                // For automatic recovery, we need to fetch the encryption session first
                print("[HomeViewModel] Fetching encryption session...")
                let session = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                    getEncryptionSession { result in
                        print("[HomeViewModel] Encryption session result: \(result)")
                        continuation.resume(with: result)
                    }
                }
                print("[HomeViewModel] Got encryption session: \(session.prefix(20))...")

                let recoveryParams = OFRecoveryParamsDTO(recoveryMethod: .automatic, encryptionSession: session, password: nil, passkeyInfo: nil)
                print("[HomeViewModel] Calling OFSDK.shared.configure...")
                let result = try await OFSDK.shared.configure(params: OFConfigureEmbeddedWalletDTO(chainId: chainId, recoveryParams: recoveryParams))
                print("[HomeViewModel] Configure succeeded! Result: \(String(describing: result))")
                self.message = "Embedded wallet configured successfully with automatic recovery.\n\n" + self.message
            }
        } catch {
            print("[HomeViewModel] Error caught: \(error)")
            print("[HomeViewModel] Error type: \(type(of: error))")
            print("[HomeViewModel] Error localized: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("[HomeViewModel] NSError domain: \(nsError.domain)")
                print("[HomeViewModel] NSError code: \(nsError.code)")
                print("[HomeViewModel] NSError userInfo: \(nsError.userInfo)")
            }
            self.message = "Error configuring embedded wallet: \(error.localizedDescription)\n\n" + self.message
            throw error
        }

    }
    
    init() {
        self.cancellable = OFSDK.shared.embeddedStatePublisher
            .replaceNil(with: .none)
            .receive(on: DispatchQueue.main)
            .assign(to: \.state, on: self)

        // Load user data on initialization
        Task {
            await loadUser()
        }
    }

    func loadUser() async {
        do {
            user = try await OFSDK.shared.getUser()
        } catch {
            message = "Error loading user: \(error)\n\n" + message
        }
    }
    
    func logout() async {
        do {
            try await OFSDK.shared.logOut()
        } catch let error {
            message = "Error logging out: \(error)\n\n" + message
            return
        }
        onLogout?()
    }
    
    func handleSetMessage(_ msg: String) {
        message = "> \(msg)\n\n" + message
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String) -> some View {
        ZStack {
            self
            if isPresented.wrappedValue {
                Text(message)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.move(edge: .top))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { isPresented.wrappedValue = false }
                        }
                    }
                    .zIndex(2)
            }
        }
    }
}
