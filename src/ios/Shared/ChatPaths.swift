//
//  ChatPaths.swift
//  MinisApp — modified build
//
//  Single source of truth for the per-identity storage root.
//  Upstream hardcodes `Library/MinisChat` in ~15 files; the vault identity
//  needs its own SQLite db + media + per-session dirs while keeping
//  providers / skills / settings shared with the main identity.
//
//  `ChatPaths.base` MUST be resolved before `ChatStore.shared` is created.
//  The identity gate keeps the main UI unmounted until the passcode is
//  entered, which guarantees that ordering.
//

import Foundation

enum ChatPaths {
    /// Storage root for the CURRENT identity. Defaults to the standard
    /// `MinisChat` so test targets and previews behave like upstream.
    nonisolated(unsafe) private static let _lock = NSLock()
    nonisolated(unsafe) private static var _base: URL = {
        let lib = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        return lib.appendingPathComponent("MinisChat", isDirectory: true)
    }()

    /// Set once at launch, right after the identity gate resolves.
    static func activate(_ kind: IdentityKind) {
        _lock.lock(); defer { _lock.unlock() }
        let lib = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        switch kind {
        case .main:
            _base = lib.appendingPathComponent("MinisChat", isDirectory: true)
        case .vault:
            _base = lib.appendingPathComponent("MinisChat_vault", isDirectory: true)
        }
    }

    /// Current per-identity root (Library/MinisChat or Library/MinisChat_vault).
    static var base: URL {
        _lock.lock(); defer { _lock.unlock() }
        return _base
    }

    static var chatDB: URL { base.appendingPathComponent("minis.db") }
    static var mediaBase: URL { base.appendingPathComponent("minis", isDirectory: true) }

    /// True when the current identity is the hidden vault.
    static var isVault: Bool { base.lastPathComponent == "MinisChat_vault" }
}
