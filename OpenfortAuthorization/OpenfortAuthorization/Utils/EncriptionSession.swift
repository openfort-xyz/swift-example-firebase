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

func getEncryptionSession(completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "https://openfort-auth-non-custodial.vercel.app/api/protected-create-encryption-session") else {
        completion(.failure(NSError(domain: "InvalidURL", code: -1, userInfo: nil)))
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: [:]) // empty body {}

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: -1, userInfo: nil)))
            return
        }
        do {
            let decoded = try JSONDecoder().decode(EncryptionSessionResponse.self, from: data)
            completion(.success(decoded.session))
        } catch {
            completion(.failure(error))
        }
    }
    task.resume()
}
