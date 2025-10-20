//
//  AppleAuthManager.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-08-28.
//

import Foundation
import AuthenticationServices
import LocalAuthentication
import CryptoKit
import UIKit

/// A helper to (optionally) prompt biometrics/passcode and then perform Sign in with Apple.
/// Call `performAppleSignIn()` to get the Apple ID Token (JWT) as `String`.
@MainActor
public final class AppleAuthManager: NSObject {

    // MARK: - Init

    /// Presentation anchor for the Apple sign-in UI
    private let anchor: ASPresentationAnchor

    /// Designated initializer (pass a window to present Apple sign-in).
    public init(presentationAnchor: ASPresentationAnchor) {
        self.anchor = presentationAnchor
        super.init()
    }

    /// Convenience init for SwiftUI (using a UIWindowScene).
    public convenience init(windowScene: UIWindowScene) {
        let window = windowScene.windows.first { $0.isKeyWindow } ?? UIWindow(windowScene: windowScene)
        self.init(presentationAnchor: window)
    }

    // MARK: - Optional Local Authentication

    /// Prompts Face ID / Touch ID / passcode as a local device authentication gate.
    /// You can skip calling this if you don't need a local gate.
    @discardableResult
    public func authenticateWithBiometrics(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var authError: NSError?
        let policy: LAPolicy = .deviceOwnerAuthentication // biometrics OR passcode
        guard context.canEvaluatePolicy(policy, error: &authError) else {
            if let err = authError { throw err }
            return false
        }

        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(policy, localizedReason: reason) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    // MARK: - Sign in with Apple

    /// Performs Sign in with Apple and returns the ID Token (JWT) as a String.
    public func performAppleSignIn(scopes: [ASAuthorization.Scope] = [.fullName, .email]) async throws -> String {
        let nonce = Self.randomNonceString()
        let hashedNonce = Self.sha256(nonce)

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = scopes
        request.nonce = hashedNonce

        return try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<String, Error>) in
            guard let self = self else {
                return
            }

            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = ControllerDelegate(anchor: self.anchor, continuation: continuation, originalNonce: nonce)
            controller.delegate = delegate
            controller.presentationContextProvider = delegate

            // Retain delegate for lifecycle of the request
            self.delegateProxy = delegate
            controller.performRequests()
        }
    }

    /// Completion-based wrapper.
    public func performAppleSignIn(
        scopes: [ASAuthorization.Scope] = [.fullName, .email],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        Task {
            do {
                let token = try await performAppleSignIn(scopes: scopes)
                completion(.success(token))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Private

    private var delegateProxy: ControllerDelegate?

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            var bytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            if status != errSecSuccess {
                fatalError("SecRandomCopyBytes failed: \(status)")
            }
            bytes.forEach { byte in
                if remaining == 0 { return }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    private func error(_ message: String, code: Int = -1) -> NSError {
        NSError(domain: "AppleAuthManager", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

// MARK: - Delegate

@MainActor
private final class ControllerDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let anchor: ASPresentationAnchor
    private let continuation: CheckedContinuation<String, Error>
    private let originalNonce: String

    init(anchor: ASPresentationAnchor, continuation: CheckedContinuation<String, Error>, originalNonce: String) {
        self.anchor = anchor
        self.continuation = continuation
        self.originalNonce = originalNonce
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        anchor
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8),
            !idToken.isEmpty
        else {
            continuation.resume(throwing: NSError(domain: "AppleAuthManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing ID token"]))
            return
        }

        // (Optional) Verify nonce on backend if needed using `originalNonce`
        continuation.resume(returning: idToken)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}
