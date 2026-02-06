//
//  EncriptionSession.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-27.
//

import Foundation

struct EncryptionSessionResponse: Decodable {
    let session: String
}

func getEncryptionSession() async throws -> String {
    guard let url = URL(string: "https://create-next-app.openfort.io/api/protected-create-encryption-session") else {
        throw NSError(domain: "InvalidURL", code: -1, userInfo: nil)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: [:])

    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(EncryptionSessionResponse.self, from: data)
    return decoded.session
}
