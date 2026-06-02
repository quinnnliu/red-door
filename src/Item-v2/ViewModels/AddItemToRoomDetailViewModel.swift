//
//  AddItemToRoomDetailViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import Foundation
import FirebaseFirestore
import SwiftUI

@Observable
final class AddItemToRoomDetailViewModel {
    let roomRepo: RoomRepository
    let itemRepo: ItemRepository = .init()
    var room: RoomV2
    let item: ItemV2
    
    var isLoading: Bool = false
    
    var selectedRDImage: RDImage?
    var isImageSelected: Bool = false
    var alertMessage: String = ""
    var showAlert: Bool = false
    
    init(
        item: ItemV2,
        room: RoomV2
    ) {
        guard let roomRepo = RoomRepository(room: room) else {
            fatalError("[ERROR] Unable to create RoomRepository with room: \(room.displayName)")
        }
        self.roomRepo = roomRepo
        self.room = room
        self.item = item
    }
}

extension AddItemToRoomDetailViewModel {
    func addItemToRoom() async {
        do {
            let _ = try await roomRepo.db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    let currentRoom = try self.roomRepo.get(id: self.room.id, in: transaction)
                    let newItemIds: [String] = Array(currentRoom.itemIds.union([self.item.id]))
                    
                    self.roomRepo.update(
                        id: self.room.id,
                        fields: [RoomV2.CodingKeys.itemIds.stringValue: newItemIds],
                        in: transaction
                    )
                    self.itemRepo.update(
                        id: self.item.id,
                        fields: [
                            ItemV2.CodingKeys.listId.stringValue: self.room.listId,
                            ItemV2.CodingKeys.isAvailable.stringValue: false
                        ],
                        in: transaction
                    )
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            })
            alertMessage = "Added \(item.name) to \(room.displayName)"
            showAlert = true
        } catch {
            alertMessage = "Failed to add \(item.name) to \(room.displayName)"
            showAlert = true
            print("[ERROR]: Failed to add \(item.name) to \(room.displayName): \(error.localizedDescription)")
        }
    }
    
//    do {
//        let _ = try await db.runTransaction({ (transaction, errorPointer) -> Any? in
//            let sfDocument: DocumentSnapshot
//            do {
//                try sfDocument = transaction.getDocument(sfReference)
//            } catch let fetchError as NSError {
//                errorPointer?.pointee = fetchError
//                return nil
//            }
//            
//            guard let oldPopulation = sfDocument.data()?["population"] as? Int else {
//                let error = NSError(
//                    domain: "AppErrorDomain",
//                    code: -1,
//                    userInfo: [
//                        NSLocalizedDescriptionKey: "Unable to retrieve population from snapshot \(sfDocument)"
//                    ]
//                )
//                errorPointer?.pointee = error
//                return nil
//            }
//            
//                // Note: this could be done without a transaction
//                //       by updating the population using FieldValue.increment()
//            transaction.updateData(["population": oldPopulation + 1], forDocument: sfReference)
//            return nil
//        })
//        print("Transaction successfully committed!")
//    } catch {
//        print("Transaction failed: \(error)")
//    }
}
