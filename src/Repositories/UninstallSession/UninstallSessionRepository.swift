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

    func setCopyPullListId(sessionId: String, _ copyId: String) async throws {
        try await update(
            id: sessionId,
            fields: [UninstallSession.CodingKeys.copyPullListId.stringValue: copyId]
        )
    }

    func setExistingPullListId(sessionId: String, _ listId: String) async throws {
        try await update(
            id: sessionId,
            fields: [UninstallSession.CodingKeys.existingPullListId.stringValue: listId]
        )
    }
}
