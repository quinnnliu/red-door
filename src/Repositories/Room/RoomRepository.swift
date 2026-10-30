//
//  RoomRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import Foundation
import Firebase

/// Rooms of a single list, generic over which kind of list that is.
///
/// `RoomV2` documents are identical in `pull_list_v2` and `installed_list_v2`,
/// so nothing on the room itself says which collection it came from. Carrying
/// the parent as a type parameter means the collection path and the
/// `LocationStatus` an added item receives are both derived from one source,
/// and a room can't be read from one list's subcollection and written to the
/// other's.
final class RoomRepository<Parent: RDListDocument>: GenericRepository<RoomV2> {

    /// Retained so writes that touch the parent list don't have to be handed
    /// the ID they already implied by constructing this repository.
    let listId: String

    // MARK: ListId init

    init(db: Firestore = Firestore.firestore(), listId: String) {
        self.listId = listId
        super.init(
            db: db,
            collectionRef: db
                .collection(Parent.collectionPath)
                .document(listId)
                .collection(RoomV2.collectionName)
        )
    }

    // MARK: List init

    convenience init(db: Firestore = Firestore.firestore(), list: Parent) {
        self.init(db: db, listId: list.id)
    }

    // MARK: Room init

    convenience init(db: Firestore = Firestore.firestore(), room: RoomV2) {
        self.init(db: db, listId: room.listId)
    }

    /// The parent list document, for guards that need its live state.
    var parentRef: DocumentReference {
        db.collection(Parent.collectionPath).document(listId)
    }
}

// MARK: - Listeners

extension RoomRepository {
    func addRoomListener(
        roomId: String,
        onChange: @escaping (Result<RoomV2, Error>) -> Void
    ) -> ListenerRegistration {
        addDocumentListener(id: roomId, onChange: onChange)
    }

    func addRoomsListener(
        onChange: @escaping (Result<[RoomV2], Error>) -> Void
    ) -> ListenerRegistration {
        addCollectionListener(onChange: onChange)
    }
}
