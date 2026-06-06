//
//  RoomRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import Foundation
import Firebase

final class RoomRepository: GenericRepository<RoomV2> {
    // MARK: PullList init
    init?(
        db: Firestore = Firestore.firestore(),
        list: any AnyRDDocument
    ) {
        guard let pullList = list as? PullListV2 else { return nil }
        super.init(db: db)
        self.collectionRef = db
            .collection(PullListV2.collectionName)
            .document(pullList.id)
            .collection(RoomV2.collectionName)
    }
    
    // MARK: ListId init
    init(
        db: Firestore = Firestore.firestore(),
        listId: String
    ) {
        super.init(db: db)
        self.collectionRef = db
            .collection(PullListV2.collectionName)
            .document(listId)
            .collection(RoomV2.collectionName)
    }
    
    // MARK: Room init
    
    init(
        db: Firestore = Firestore.firestore(),
        room: RoomV2
    ) {
        super.init(db: db)
        self.collectionRef = db
            .collection(PullListV2.collectionName)
            .document(room.listId)
            .collection(RoomV2.collectionName)
    }
}

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
