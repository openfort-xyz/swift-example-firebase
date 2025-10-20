//
//  FundingPanelView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI

struct FundingPanelView: View {
    let handleSetMessage: (String) -> Void

    @State private var showSheet: Bool = false
    @State private var step: StepEnum = .start
    @State private var fundAmount: String = "0.02"
    @State private var accountAddress: String = "0x12345...ABCD" // Replace with your logic
    @State private var accountBalance: Double = 0.0 // Replace with your logic
    @State private var service: FundingService?
    @State private var txId: String = UUID().uuidString

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Funding").font(.headline)
            Text("Add funds is on-ramp or transfer funds from another wallet.")
            Button("Add funds") {
                showSheet = true
            }
            .buttonStyle(.bordered)
            .sheet(isPresented: $showSheet) {
                fundingDialog
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }

    @ViewBuilder
    var fundingDialog: some View {
        VStack {
            switch step {
            case .start:
                Text("Add funds to your Openfort wallet").font(.title2).bold().padding()
                HStack {
                    TextField("Amount", text: $fundAmount)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                    Text("ETH")
                        .font(.system(size: 24))
                        .padding(.leading, 4)
                }
                .padding()

                ForEach(FundingService.services) { service in
                    Button(service.name) {
                        self.service = service
                        step = .serviceProgress
                        // Simulate: launch URL (in real app, use UIApplication.shared.open)
                        handleSetMessage("Opened \(service.name) for funding")
                        // Start polling or your onramp logic here...
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            step = .completed
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: service.color))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button("Transfer from wallet") {
                    step = .wallet
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .foregroundColor(.white)
                .cornerRadius(8)

            case .serviceProgress:
                if let service = service {
                    VStack {
                        Text("In Progress").font(.headline)
                        Image(systemName: "clock.arrow.circlepath")
                            .resizable().frame(width: 48, height: 48)
                            .padding()
                        Text("Go back to \(service.name) to finish funding your account.")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            case .wallet:
                Text("Transfer from wallet").font(.title2).bold().padding(.top)
                Text("Connect a wallet to deposit funds or send funds manually to your wallet address.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                AddFundsWithWagmiView(
                    fundAddress: accountAddress,
                    fundAmount: fundAmount,
                    callback: {
                        step = .completed
                        handleSetMessage("Funds added successfully!")
                    }
                )
                Button("Send funds manually") {
                    step = .manual
                }
                .padding()
            case .manual:
                Text("Send funds").font(.title2).bold().padding(.top)
                Text("Send funds directly to your wallet by copying your wallet address.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                VStack(spacing: 10) {
                    Text("Make sure to send on **Polygon Amoy**")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.bottom)
                    HStack {
                        Text("Wallet address: \(accountAddress)")
                            .font(.callout)
                            .lineLimit(1)
                        Button("Copy") {
                            UIPasteboard.general.string = accountAddress
                        }
                        .foregroundColor(.blue)
                    }
                    if accountBalance > 0 {
                        Text(String(format: "%.4f ETH", accountBalance))
                            .font(.footnote)
                            .foregroundColor(.green)
                    }
                }
            case .completed:
                VStack(spacing: 20) {
                    if let service = service {
                        Text("Account was successfully funded using \(service.name)!").font(.title3)
                    } else {
                        Text("Account was successfully funded!").font(.title3)
                    }
                    Button("Done") {
                        showSheet = false
                        step = .start
                        handleSetMessage("Funds added successfully!")
                    }
                    .padding()
                }
            }
        }
        .padding()
        .onDisappear {
            step = .start
        }
        .frame(maxWidth: 400)
    }

    // MARK: - Enums & Service Model

    enum StepEnum {
        case start, serviceProgress, wallet, manual, completed
    }

    struct FundingService: Identifiable {
        let id = UUID()
        let name: String
        let color: String // Hex color string
        static let services: [FundingService] = [
            FundingService(name: "Coinbase Onramp", color: "#0051fc"),
            FundingService(name: "Moonpay", color: "#7d00fe"),
        ]
    }
}

// MARK: - Color hex initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        var color: UInt64 = 0
        scanner.scanLocation = hex.hasPrefix("#") ? 1 : 0
        scanner.scanHexInt64(&color)
        let r = Double((color & 0xFF0000) >> 16) / 255
        let g = Double((color & 0x00FF00) >> 8) / 255
        let b = Double(color & 0x0000FF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
