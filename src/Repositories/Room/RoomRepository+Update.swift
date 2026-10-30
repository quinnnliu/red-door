//
//  RoomRepository+Update.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/29/26.
//

import Foundation
import Firebase

// MARK: - Parent guard

extension RoomRepository {

    func openParent(in transaction: Transaction) throws -> Parent {
        let snapshot = try transaction.getDocument(parentRef)
        guard snapshot.exists else { throw StaleWriteError.documentGone }
        let parent = try snapshot.data(as: Parent.self)
        guard parent.acceptsChanges else { throw StaleWriteError.listClosed(name: parent.displayName) }
        return parent
    }
}

// MARK: - Update room

extension RoomRepository {

    /// Writes fields to a room only while its list and the room both still
    /// exist and the list accepts changes.
    func updateRoom(id roomId: String, fields: [String: Any]) async throws {
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                _ = try self.openParent(in: transaction)
                _ = try self.get(id: roomId, transaction: transaction)
                self.update(id: roomId, fields: fields, transaction: transaction)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
}
