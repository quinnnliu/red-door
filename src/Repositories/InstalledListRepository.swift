//
//  InstalledListRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/8/26.
//

import Firebase
import Foundation

final class InstalledListRepository: GenericRepository<InstalledListV2> {
    func getAllInstalled() async throws -> [InstalledListV2] {
        let snapshot = try await collectionRef
            .whereField(InstalledListV2.CodingKeys.uninstalled.stringValue, isEqualTo: false)
            .order(by: InstalledListV2.CodingKeys.installDate.stringValue, descending: true)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: InstalledListV2.self) }
    }
}

// MARK: - Delete

enum InstalledListDeleteError: LocalizedError {
    case notUninstalled

    var errorDescription: String? {
        switch self {
        case .notUninstalled: "Only uninstalled lists can be deleted."
        }
    }
}

extension InstalledListRepository {
    /// Deletes an uninstalled list, its rooms, its uninstall summary and its
    /// images. Items are left untouched.
    func delete(_ listId: String) async throws {
        let roomRepo = RoomRepository<InstalledListV2>(listId: listId)
        let roomSnapshot = try await roomRepo.collectionRef.getDocuments()
        let roomRefs = roomSnapshot.documents.map(\.reference)
        let rooms = roomSnapshot.documents.compactMap { try? $0.data(as: RoomV2.self) }
        let sessionRef = db.collection(UninstallSession.collectionPath).document(listId)

        let deleted = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let list = try self.get(id: listId, transaction: transaction)
                guard list.uninstalled else { throw InstalledListDeleteError.notUninstalled }

                for ref in roomRefs {
                    transaction.deleteDocument(ref)
                }
                transaction.deleteDocument(sessionRef)
                self.delete(id: listId, transaction: transaction)
                return list
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let list = deleted as? InstalledListV2 else { return }

        // Storage deletes happen after the document write; a failure only
        // orphans files, so it's logged rather than thrown.
        do {
            try await FirebaseImageManager.shared.deleteDocumentImages(ownerId: list.id, imageType: .listV2)
        } catch {
            print("[WARN]: Deleted installed list \(listId) but failed to clean up its images: \(error.localizedDescription)")
        }
        for room in rooms {
            do {
                try await FirebaseImageManager.shared.deleteDocumentImages(ownerId: room.imageOwnerId, imageType: .roomBefore)
            } catch {
                print("[WARN]: Deleted room \(room.id) but failed to clean up its images: \(error.localizedDescription)")
            }
        }
    }
}
