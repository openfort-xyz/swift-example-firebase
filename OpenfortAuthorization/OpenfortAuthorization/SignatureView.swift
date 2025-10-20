//
//  SignatureView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-01.
//

import SwiftUI
import OpenfortSwift

struct SignatureView: View {
    var message: String = "Hello World"
    var onSign: (() -> Void)?
    var onLogout: (() -> Void)?
    
    @State private var alertMessage: String?
    private let openfort = OFSDK.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Signature")
                .font(.system(size: 24, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
            
            Spacer().frame(height: 40)
            
            // Message "divider" and label
            HStack {
                VStack(spacing: 0) {
                    ZStack {
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, 8)
                        HStack(spacing: 0) {
                            Text("Message: ")
                                .font(.subheadline)
                                .foregroundColor(Color.gray)
                                .background(Color.white)
                                .padding(.horizontal, 2)
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(Color.gray)
                                .background(Color.white)
                                .padding(.horizontal, 2)
                        }
                        .padding(.horizontal)
                        .background(Color.white)
                    }
                    .frame(maxWidth: .infinity, minHeight: 40)
                    Spacer().frame(height: 16)
                    // Sign message button
                    Button(action: { sign() }) {
                        Text("Sign message")
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color.white)
                            .foregroundColor(Color.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: 400)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            
            if let alertMessage = alertMessage {
                ScrollView(.horizontal) {
                    Text(alertMessage)
                        .padding()
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            // Logout button
            Button(action: { logout() }) {
                Text("Logout")
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.white)
                    .foregroundColor(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(8)
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .background(Color(.systemBackground))
    }
    
    private func sign() {
        let params = OFSignMessageParams(message: message)
        openfort.signMessage(params: params) { result in
            switch result {
            case .success(let signedMessage):
                alertMessage = signedMessage
                onSign?()
            case .failure(let error):
                self.alertMessage = "Error: \(error)"
            }
        }
    }
    
    private func logout() {
        onLogout?()
    }
}

struct SignatureView_Previews: PreviewProvider {
    static var previews: some View {
        SignatureView(
            onSign: { print("Sign") },
            onLogout: { print("Logout") }
        )
    }
}
