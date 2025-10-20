//
//  RedirectManager.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-12.
//

import Foundation

struct RedirectManager {
    static var scheme: String {
        // Example: openfortsample
        Bundle.main.bundleIdentifier?
            .components(separatedBy: ".")
            .last?
            .lowercased() ?? "openfortsample"
    }
    
    static func makeLink(path: String, params: [String: String] = [:]) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = path
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url
    }
}
