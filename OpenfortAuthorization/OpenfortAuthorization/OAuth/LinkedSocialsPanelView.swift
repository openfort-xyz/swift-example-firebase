//
//  LinkedSocialsPanelView.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-06.
//

import SwiftUI
import OpenfortSwift

struct LinkedSocialsPanelView: View {
    let user: OFUser?
    let handleSetMessage: (String) -> Void
    @State var userResponse: OFUser?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Linked socials").font(.headline)
            HStack {
                Text("Get user: ").fontWeight(.medium)
                GetUserButton(handleSetMessage: handleSetMessage)
            }
            Text("OAuth methods")
            // Add real OAuth buttons as needed
            HStack(spacing: 8) {
                LinkOAuthButton(provider: "google", user: userResponse, handleSetMessage: handleSetMessage)
                    .font(.caption)
                LinkOAuthButton(provider: "twitter", user: userResponse, handleSetMessage: handleSetMessage)
                LinkOAuthButton(provider: "facebook", user: userResponse, handleSetMessage: handleSetMessage)
            }
            Button("Link a Wallet") { handleSetMessage("Link wallet clicked") }
        }.onAppear() {
            
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
