//
//  IdentityGate.swift
//  MinisApp — identity gate (modified build)
//
//  Startup passcode gate with two identities:
//    • 2810  → main identity  (Library/MinisChat, default storage)
//    • 112233 → vault identity (Library/MinisChat_vault, separate minis.db
//      + media; providers/skills/settings are shared)
//
//  The correct digest lives only as a salted SHA-256 hex string; the
//  passcodes never appear in the binary.
//
//  IMPORTANT: this must be consulted BEFORE any code touches
//  `ChatStore.shared` (the singleton path is chosen from the resolved
//  identity). The app entry view keeps the main UI unmounted until the
//  gate resolves, which guarantees that ordering.
//

import Foundation
import CryptoKit

enum IdentityKind: String {
    case main = "main"
    case vault = "vault"
}

@MainActor
final class IdentityGate: ObservableObject {
    static let shared = IdentityGate()

    /// Nil until the correct passcode is entered. Drives the app root.
    @Published private(set) var resolved: IdentityKind?
    /// Bumped on every wrong attempt so the UI can shake the field.
    @Published private(set) var failedAttempt = 0

    private static let salt = "om.v1."

    // Salted SHA-256 digests of the passcodes.
    private static let digests: [String: IdentityKind] = [
        "61e4a021f6cdcfa8dfcc108d4d652ce93c73f1236d2485bf22405769af12fb19": .main,
        "eaa1f6dc634040f21832fb7000cb7e9441f87abe21e9962d6a8aa83febd7bed8": .vault,
    ]

    private init() {}

    /// Verify a passcode. On success resolves the identity for this launch.
    @discardableResult
    func submit(_ code: String) -> Bool {
        let digest = Self.digest(of: code)
        guard let kind = Self.digests[digest] else {
            failedAttempt += 1
            return false
        }
        // Pin the storage root BEFORE publishing `resolved`: the launch-time
        // migration task creates ChatStore.shared as soon as it sees a
        // resolution, and that singleton bakes in the directory.
        ChatPaths.activate(kind)
        resolved = kind
        return true
    }

    /// Background launches (BGTask / intent / widget refresh) never show the
    /// passcode screen. They belong to the main identity, so resolve to it
    /// rather than leaving the store unresolved.
    func resolveForBackgroundLaunch() {
        guard resolved == nil else { return }
        resolved = .main
        ChatPaths.activate(.main)
    }

    static func digest(of code: String) -> String {
        let d = SHA256.hash(data: Data((salt + code).utf8))
        return d.map { String(format: "%02x", $0) }.joined()
    }
}
