//
//  SignaturesPanelView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-05.
//

import SwiftUI
import OpenfortSwift

struct SignaturesPanelView: View {
    let handleSetMessage: (String) -> Void
    let embeddedState: OFEmbeddedState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signatures")
                .font(.headline)
            HStack {
                Text("Message: ").fontWeight(.medium)
                Text("Hello World!")
            }
            SignMessageButton(handleSetMessage: { message in
                handleSetMessage("Signed message: \(message)")
            }, embeddedState: embeddedState)
            HStack {
                Text("Typed message: ").fontWeight(.medium)
                SignTypedDataButton(handleSetMessage: { message in
                    handleSetMessage("Signed typed data: \(message)")
                }, embeddedState: embeddedState)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
