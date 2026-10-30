//
//  RepositoryError.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/31/26.
//

import Firebase
import Foundation

enum RepositoryError: String, Error {
    case decodeFailure
    case documentNotFound
    case sessionComplete
    case missingCopyAddress
}

extension RepositoryError {

    /// True when a listener fired because its document was deleted. That is a
    /// normal end of life for a detail screen — an install deletes the pull
    /// list and its rooms out from under whatever is still listening — so
    /// callers skip their error alert rather than blaming the user for it.
    static func isDocumentNotFound(_ error: Error) -> Bool {
        (error as? RepositoryError) == .documentNotFound
    }
}

/// A write built from what a screen was showing, rejected because its target
/// changed first — the list was installed or deleted on another device, the
/// list was uninstalled, or the documents no longer match what the screen
/// assumed. Thrown from inside transactions, so nothing was written.
enum StaleWriteError: LocalizedError {
    /// The list or room no longer exists.
    case documentGone
    /// The installed list was uninstalled, so it is a record, not a placement.
    /// Carries the list's name so the alert can say which.
    case listClosed(name: String)
    /// Everything still exists, but no longer matches what the screen assumed.
    case stateChanged

    /// Recognizes every way a write finds its target gone: this type, a
    /// listener-style `documentNotFound`, and Firestore's own `notFound` from a
    /// plain `updateData` on a missing document.
    init?(_ error: Error) {
        if let stale = error as? StaleWriteError {
            self = stale
        } else if RepositoryError.isDocumentNotFound(error) {
            self = .documentGone
        } else if case let nsError = error as NSError,
                  nsError.domain == FirestoreErrorDomain,
                  nsError.code == FirestoreErrorCode.notFound.rawValue {
            self = .documentGone
        } else {
            return nil
        }
    }

    /// Whether the screen the user is on can no longer be used. `stateChanged`
    /// leaves it up, because its listeners have already refreshed it.
    var resetsNavigation: Bool {
        switch self {
        case .documentGone, .listClosed: true
        case .stateChanged: false
        }
    }

    var errorDescription: String? {
        switch self {
        case .documentGone:
            "This list or room no longer exists. It may have been installed or deleted on another device."
        case .listClosed(let name):
            "\(name) was uninstalled and can no longer be changed."
        case .stateChanged:
            "This changed on another device before your update could be saved. Reopen it to see the latest, then try again."
        }
    }
}

/// Thrown by an assignment transaction that found nothing it could apply.
///
/// Carries the documents as they were read inside the transaction, not the
/// caller's copies, so callers can name the items and say where they actually
/// ended up.
enum ItemAssignmentError: Error {
    case noEligibleItems(unavailable: [ItemV2], duplicates: [ItemV2])

    static func eligibleItems(
        from items: [ItemV2],
        alreadyIn existingIds: Set<String>
    ) throws -> [ItemV2] {
        var eligible: [ItemV2] = []
        var unavailable: [ItemV2] = []
        var duplicates: [ItemV2] = []

        for item in items {
            if existingIds.contains(item.id) {
                duplicates.append(item)
            } else if item.location.status != .inStorage {
                unavailable.append(item)
            } else {
                eligible.append(item)
            }
        }

        guard !eligible.isEmpty else {
            throw ItemAssignmentError.noEligibleItems(unavailable: unavailable, duplicates: duplicates)
        }
        return eligible
    }
}
