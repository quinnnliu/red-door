//
//  AddItemToDocumentSheetViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/24/26.
//

import Foundation
import FirebaseFirestore

@Observable
final class AddItemToDocumentSheetViewModel {
    var selectedItems: Set<ItemV2> = []
    let destination: AddItemsToListableDestination
    private let itemRepo: ItemRepository = .init()

    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertText: String = ""
    var showSelectedItems: Bool = false

    init(destination: AddItemsToListableDestination) {
        self.destination = destination
    }
}

// MARK: - Selection

extension AddItemToDocumentSheetViewModel {
    func isSelected(_ item: ItemV2) -> Bool {
        selectedItems.contains(item)
    }

    func select(_ item: ItemV2) {
        selectedItems.insert(item)
    }

    func deselect(_ item: ItemV2) {
        selectedItems.remove(item)
    }

    func deselectAll() {
        selectedItems.removeAll()
        showSelectedItems = false
    }
}

// MARK: - Add Items

extension AddItemToDocumentSheetViewModel {
    func addItemsToDocument() async -> Bool {
        guard !selectedItems.isEmpty else { return false }

        isLoading = true
        defer { isLoading = false }

        switch destination {
        case .room(let room):
            return await addItemsToPullListRoom(items: selectedItems, room: room)
        case .essentialsGroup(let group):
            return await addItemsToEssentialsGroup(items: selectedItems, group: group)
        }
    }
}

// MARK: - Private Transaction Methods

private extension AddItemToDocumentSheetViewModel {

    func addItemsToPullListRoom(items: Set<ItemV2>, room: RoomV2) async -> Bool {
        let roomRepo = RoomRepository(room: room)
        let itemRepo = self.itemRepo
        let itemIds = items.map { $0.id }

        do {
            let _ = try await roomRepo.db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    let currentRoom = try roomRepo.get(id: room.id, transaction: transaction)
                    let currentItems = try itemRepo.get(ids: itemIds, transaction: transaction)

                    var unavailableNames: [String] = []
                    var duplicateNames: [String] = []
                    var validItems: [ItemV2] = []

                    for item in currentItems {
                        if item.location.status != .inStorage {
                            unavailableNames.append(item.displayName)
                        } else if currentRoom.itemIds.contains(item.id) {
                            duplicateNames.append(item.displayName)
                        } else {
                            validItems.append(item)
                        }
                    }

                    guard !validItems.isEmpty else {
                        throw AddItemsError.noValidItems(
                            unavailable: unavailableNames,
                            duplicates: duplicateNames
                        )
                    }

                    let newItemIds = currentRoom.itemIds.union(Set(validItems.map { $0.id }))

                    guard let locationData = try? Firestore.Encoder().encode(
                        DocumentLocation(status: .inPullList, locationId: room.listId)
                    ) else { return nil }

                    roomRepo.update(
                        id: room.id,
                        fields: [RoomV2.CodingKeys.itemIds.stringValue: Array(newItemIds)],
                        transaction: transaction
                    )

                    for item in validItems {
                        itemRepo.update(
                            id: item.id,
                            fields: [ItemV2.CodingKeys.location.stringValue: locationData],
                            transaction: transaction
                        )
                    }

                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            })
            return true
        } catch let error as AddItemsError {
            handleError(error)
            return false
        } catch {
            handleError(.transactionFailed(error))
            return false
        }
    }

    func addItemsToEssentialsGroup(items: Set<ItemV2>, group: EssentialsGroup) async -> Bool {
        let essentialsRepo = EssentialsRepository()
        let itemRepo = self.itemRepo
        let itemIds = items.map { $0.id }

        do {
            let _ = try await essentialsRepo.db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    let currentGroup = try essentialsRepo.get(id: group.id, transaction: transaction)
                    let currentItems = try itemRepo.get(ids: itemIds, transaction: transaction)

                    var unavailableNames: [String] = []
                    var duplicateNames: [String] = []
                    var validItems: [ItemV2] = []

                    for item in currentItems {
                        if item.location.status != .inStorage {
                            unavailableNames.append(item.displayName)
                        } else if currentGroup.itemIds.contains(item.id) {
                            duplicateNames.append(item.displayName)
                        } else {
                            validItems.append(item)
                        }
                    }

                    guard !validItems.isEmpty else {
                        throw AddItemsError.noValidItems(
                            unavailable: unavailableNames,
                            duplicates: duplicateNames
                        )
                    }

                    let newItemIds = currentGroup.itemIds.union(Set(validItems.map { $0.id }))

                    essentialsRepo.update(
                        id: group.id,
                        fields: [EssentialsGroup.CodingKeys.itemIds.stringValue: Array(newItemIds)],
                        transaction: transaction
                    )

                    for item in validItems {
                        itemRepo.update(
                            id: item.id,
                            fields: [ItemV2.CodingKeys.essentialGroupId.stringValue: group.id],
                            transaction: transaction
                        )
                    }

                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            })
            return true
        } catch let error as AddItemsError {
            handleError(error)
            return false
        } catch {
            handleError(.transactionFailed(error))
            return false
        }
    }
}

// MARK: - Error Handling

private extension AddItemToDocumentSheetViewModel {
    enum AddItemsError: Error {
        case noValidItems(unavailable: [String], duplicates: [String])
        case transactionFailed(Error)
    }

    func handleError(_ error: AddItemsError) {
        switch error {
        case .noValidItems(let unavailable, let duplicates):
            var messages: [String] = []
            if !unavailable.isEmpty {
                messages.append("Unavailable: \(unavailable.joined(separator: ", "))")
            }
            if !duplicates.isEmpty {
                messages.append("Already added: \(duplicates.joined(separator: ", "))")
            }
            alertText = messages.joined(separator: "\n")
            showAlert = true
        case .transactionFailed(let error):
            print("[FATAL ERROR]: Failed to add items to \(destination.document.displayName): \(error.localizedDescription)")
            alertText = "[ERROR]: A code error has occurred."
            showAlert = true
        }
    }
}
