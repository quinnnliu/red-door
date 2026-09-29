//
//  UninstallSessionRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Firebase

final class UninstallSessionRepository: ListSessionRepository<UninstallSession> {

    func assignEssentials(sessionId: String, destination: UninstallDestination?) async throws {
        let key = UninstallSession.CodingKeys.essentialsDestination.stringValue
        let value: Any = try destination.map { try Firestore.Encoder().encode($0) } ?? FieldValue.delete()
        try await update(id: sessionId, fields: [key: value])
    }

    /// Writes the copy's ID and address together so the two can never drift:
    /// a copy with an ID but no address would fail at commit, and one with an
    /// address but no ID has nothing to route items to.
    func setCopyDestination(sessionId: String, copyId: String, address: Address) async throws {
        try await update(
            id: sessionId,
            fields: [
                UninstallSession.CodingKeys.copyPullListId.stringValue: copyId,
                UninstallSession.CodingKeys.copyListAddress.stringValue: try Firestore.Encoder().encode(address)
            ]
        )
    }

    func setExistingPullListId(sessionId: String, _ listId: String) async throws {
        try await update(
            id: sessionId,
            fields: [UninstallSession.CodingKeys.existingPullListId.stringValue: listId]
        )
    }
}
