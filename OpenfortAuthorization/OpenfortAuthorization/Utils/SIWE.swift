//
//  SIWE.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-08.
//

import Foundation
class SIWEUtils {
    private static func createSIWEMessage(
        domain: String,
        address: String,
        statement: String? = nil,
        uri: String,
        version: String = "1",
        chainId: Int = 1,
        nonce: String,
        issuedAt: String = ISO8601DateFormatter().string(from: Date()),
        expirationTime: String? = nil
    ) -> String {
        var lines: [String] = []
        lines.append("\(domain) wants you to sign in with your Ethereum account:")
        lines.append(address)
        lines.append("")

        if let statement = statement {
            lines.append(statement)
            lines.append("")
        }

        lines.append("URI: \(uri)")
        lines.append("Version: \(version)")
        lines.append("Chain ID: \(chainId)")
        lines.append("Nonce: \(nonce)")
        lines.append("Issued At: \(issuedAt)")
        if let expirationTime = expirationTime {
            lines.append("Expiration Time: \(expirationTime)")
        }

        return lines.joined(separator: "\n")
    }

    public static func createSIWEMessage(
        address: String,
        nonce: String,
        chainId: Int
    ) -> String {
        return createSIWEMessage(
            domain: "domain",
            address: address,
            statement: "By signing, you are proving you own this wallet and logging in. This does not initiate a transaction or cost any fees.",
            uri: "uri",
            version: "1",
            chainId: chainId,
            nonce: nonce
        )
    }

    
}
