//
//  GetUserButton.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-06.
//

import SwiftUI
import OpenfortSwift

struct GetUserButton: View {
    var handleSetMessage: (String) -> Void
    @State private var isLoading = false

    var body: some View {
        Button(action: {
            Task {
                await handleUserMessage()
            }
        }) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity)
            } else {
                Text("Get user")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.bordered)
        .disabled(isLoading)
    }

    private func handleUserMessage() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let user = try await OFSDK.shared.getUser()
            let pretty = prettyPrint(user)
            handleSetMessage(pretty)
        } catch {
            print("Failed to get user: \(error)")
            handleSetMessage("Failed to get user. Please try again.")
        }
    }

    private func prettyPrint<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(value),
              let str = String(data: data, encoding: .utf8) else {
            return "\(value)"
        }
        return str
    }
}
