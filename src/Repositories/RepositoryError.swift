//
//  RepositoryError.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/31/26.
//

enum RepositoryError: String, Error {
    case decodeFailure
}

/// Thrown by an assignment transaction that found nothing it could apply.
///
/// Carries the documents as they were read inside the transaction, not the
/// caller's copies, so callers can name the items and say where they actually
/// ended up.
enum ItemAssignmentError: Error {
    case noEligibleItems(unavailable: [ItemV2], duplicates: [ItemV2])
}

extension ItemAssignmentError {

    /// Splits freshly-read items into the ones that can be assigned and the
    /// ones that can't, throwing when none survive.
    ///
    /// Being a duplicate takes priority over being unavailable: an item already
    /// in the destination necessarily reads as assigned somewhere, so calling
    /// it "unavailable" would be true but useless.
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
