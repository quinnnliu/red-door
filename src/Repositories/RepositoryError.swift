//
//  RepositoryError.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/31/26.
//

enum RepositoryError: String, Error {
    case decodeFailure
    case sessionComplete
    case missingCopyAddress
}

/// Thrown by an assignment transaction that found nothing it could apply.
///
/// Carries the documents as they were read inside the transaction, not the
/// caller's copies, so callers can name the items and say where they actually
/// ended up.
enum ItemAssignmentError: Error {
    case noEligibleItems(unavailable: [ItemV2], duplicates: [ItemV2])

    /// The parent list stopped accepting items — it was uninstalled while the
    /// add flow was open. Carries the list's name so the alert can say which.
    case destinationClosed(name: String)
    
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
