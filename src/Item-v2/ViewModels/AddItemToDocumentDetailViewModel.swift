//
//  AddItemToDocumentDetailViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import Foundation
import FirebaseFirestore

@Observable
final class AddItemToDocumentDetailViewModel {
    let context: AddItemDocumentContext
    private let itemRepo: ItemRepository = .init()

    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertText: String = ""

    init(context: AddItemDocumentContext) {
        self.context = context
    }
}

// MARK: - Add Item

extension AddItemToDocumentDetailViewModel {
    func addItem() async {
        isLoading = true
        defer { isLoading = false }

        switch context {
        case .itemToPullListRoom(let item, let room):
            await addItemToPullListRoom(item: item, room: room)
        case .itemToEssentialsGroup(let item, let group):
            await addItemToEssentialsGroup(item: item, group: group)
        }
    }
}

// MARK: - Private Transaction Methods

private extension AddItemToDocumentDetailViewModel {

    func addItemToPullListRoom(item: ItemV2, room: RoomV2) async {
        let roomRepo = RoomRepository(room: room)
        let itemRepo = self.itemRepo

        do {
            let _ = try await roomRepo.db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    let currentRoom = try roomRepo.get(id: room.id, transaction: transaction)
                    let currentNewItem = try itemRepo.get(id: item.id, transaction: transaction)
                    guard !currentRoom.itemIds.contains(currentNewItem.id) else { throw AddItemError.itemAlreadyInDestination(currentNewItem, destinationDocument: currentRoom) }
                    guard currentNewItem.status == .inStorage else { throw AddItemError.itemUnavailable(currentNewItem) }
                    
                    let newItemIds: [String] = Array(currentRoom.itemIds.union([item.id]))

                    roomRepo.update(
                        id: room.id,
                        fields: [RoomV2.CodingKeys.itemIds.stringValue: newItemIds],
                        transaction: transaction
                    )
                    itemRepo.update(
                        id: item.id,
                        fields: [
                            ItemV2.CodingKeys.status.stringValue: LocationStatus.inPullList.rawValue,
                            ItemV2.CodingKeys.locationId.stringValue: room.listId
                        ],
                        transaction: transaction
                    )
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            })
        } catch let error as AddItemError {
            handleAddItemError(error)
        } catch {
            handleAddItemError(AddItemError.genericError(item: item, destinationDocument: room, error: error))
        }
    }

    func addItemToEssentialsGroup(item: ItemV2, group: EssentialsGroup) async {
        let essentialsRepo = EssentialsRepository()
        let itemRepo = self.itemRepo

        do {
            let _ = try await essentialsRepo.db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    let currentGroup = try essentialsRepo.get(id: group.id, transaction: transaction)
                    let currentNewItem = try itemRepo.get(id: item.id, transaction: transaction)
                    guard currentNewItem.status == .inStorage else { throw AddItemError.itemUnavailable(currentNewItem) }
                    
                    var newItemIds = currentGroup.itemIds
                    guard !newItemIds.contains(item.id) else { throw AddItemError.itemAlreadyInDestination(item, destinationDocument: group) }
                    newItemIds.append(item.id)
                    
                    essentialsRepo.update(
                        id: group.id,
                        fields: [EssentialsGroup.CodingKeys.itemIds.stringValue: newItemIds],
                        transaction: transaction
                    )
                    itemRepo.update(
                        id: item.id,
                        fields: [ItemV2.CodingKeys.essentialGroupId.stringValue: group.id],
                        transaction: transaction
                    )
                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            })
        } catch let error as AddItemError {
            handleAddItemError(error)
        } catch {
            handleAddItemError(AddItemError.genericError(item: item, destinationDocument: group, error: error))
        }
    }
}

// MARK: - Error Handling

private extension AddItemToDocumentDetailViewModel {
    enum AddItemError: Error {
        case itemUnavailable(_ item: ItemV2)
        case itemAlreadyInDestination(_ item: ItemV2, destinationDocument: any RDDocument)
        case genericError(item: ItemV2, destinationDocument: any RDDocument, error: Error)
    }
    
    func handleAddItemError(_ error: AddItemError) {
        switch error {
        case .itemAlreadyInDestination(let item, let destinationDocument):
            alertText = "[ERROR]: Item \(item.displayName) is already assigned to this \(destinationDocument.displayName). Try refreshing."
            showAlert = true
        case .itemUnavailable(let item):
            alertText = "[ERROR]: Item \(item.displayName) is not available to be added. It is currently \(item.status.displayTitle)."
            showAlert = true
        case .genericError(let item, let destinationDocument, let error):
            print("[FATAL ERROR]: Failed to add \(item.displayName) to \(destinationDocument.displayName): \(error.localizedDescription)")
            alertText = "[ERROR]: A code error has occurred. "
        }
    }
}
