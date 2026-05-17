//
//  RoomRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import Foundation
import Firebase

final class RoomRepository: GenericRepository<RoomV2> {
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
}
