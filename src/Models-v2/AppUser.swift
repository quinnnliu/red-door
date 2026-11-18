//
//  AppUser.swift
//  RedDoor
//
//  Created by Quinn Liu on 11/18/26.
//

/// Allowlist entry for an account. The document id is the lowercased email.
struct AppUser: RDDocument {
    var email: String
    var isAdmin: Bool

    /// Derived, not stored: the Firestore document id is the email.
    var id: String { email }
    var baseName: String { email }

    static let collectionName = "users"
    static let orderByField = "email"
    static let searchField = "email"

    enum CodingKeys: String, CodingKey {
        case email
        case isAdmin = "is_admin"
    }

    init(email: String, isAdmin: Bool = false) {
        self.email = AppUser.normalizeEmail(email)
        self.isAdmin = isAdmin
    }

    static func normalizeEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
