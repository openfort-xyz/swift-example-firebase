//
//  AccountActionsView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-04.
//

import SwiftUI
import OpenfortSwift

struct AccountActionsView: View {
    let handleSetMessage: (String) -> Void

    @State private var isProviderEnabled: Bool = true
    @State private var sessionKey: String? = nil
    @State private var selectedSession: String = "1day"

    let sessionMethods: [(id: String, title: String)] = [
        (id: "1hour", title: "1 Hour"),
        (id: "1day", title: "1 Day"),
        (id: "1month", title: "1 Month"),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Account actions")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 4)

            // Provider Switch
            HStack(spacing: 10) {
                Toggle(isOn: $isProviderEnabled) {
                    Text("EIP-1193 Provider")
                        .font(.subheadline)
                }
                .toggleStyle(SwitchToggleStyle())
            }
            .padding(.bottom, 8)

            // Mint button logic
            if isProviderEnabled {
                EIP1193MintButton(handleSetMessage: handleSetMessage, openfort: OFSDK.shared)
            } else {
                VStack(spacing: 6) {
                    AlertView(
                        title: "Backend Action!",
                        description: "This mode creates an API call to your backend to mint the NFT."
                    )
                    BackendMintButton(handleSetMessage: handleSetMessage)
                }
            }

            // Session key radio buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("Session key duration")
                    .font(.headline)
                ForEach(sessionMethods, id: \.id) { method in
                    HStack {
                        RadioButton(
                            isSelected: selectedSession == method.id,
                            isDisabled: sessionKey != nil,
                            action: { selectedSession = method.id }
                        )
                        Text(method.title)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.top, 8)

            // Session button logic
            if isProviderEnabled {
                EIP1193CreateSessionButton(
                    handleSetMessage: handleSetMessage,
                    setSessionKey: { sessionKey = $0 }, sessionKey: $sessionKey
                )
            } else {
                BackendCreateSessionButton(
                    handleSetMessage: handleSetMessage,
                    setSessionKey: { sessionKey = $0 },
                    sessionKey: sessionKey)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

// MARK: - Supporting Views

struct RadioButton: View {
    var isSelected: Bool
    var isDisabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(isDisabled ? Color.gray : Color.blue, lineWidth: 2)
                    .frame(width: 20, height: 20)
                if isSelected {
                    Circle()
                        .fill(isDisabled ? Color.gray : Color.blue)
                        .frame(width: 12, height: 12)
                }
            }
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }
}

struct AlertView: View {
    let title: String
    let description: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.caption)
        }
        .padding(10)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}
