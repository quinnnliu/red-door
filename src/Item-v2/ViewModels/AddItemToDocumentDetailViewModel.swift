//
//  AddItemToDocumentDetailViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import Foundation

@Observable
final class AddItemToDocumentDetailViewModel {
    let item: ItemV2
    let destination: AddItemsToListableDestination
    private let itemRepo: ItemRepository = .init()

    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertText: String = ""

    init(item: ItemV2, destination: AddItemsToListableDestination) {
        self.item = item
        self.destination = destination
    }
}

// MARK: - Add Item

extension AddItemToDocumentDetailViewModel {
    func addItem() async {
        isLoading = true
        defer { isLoading = false }

        switch destination {
        case .room(let room, let listKind):
            await addItemToRoom(item: item, room: room, listKind: listKind)
        case .essentialsGroup(let group):
            await addItemToEssentialsGroup(item: item, group: group)
        }
    }
}

// MARK: - Private Assignment Methods

private extension AddItemToDocumentDetailViewModel {

    /// The switch erases `listKind` back into a concrete `RoomRepository`
    /// parameter, which is what picks the collection and the item's new status.
    func addItemToRoom(item: ItemV2, room: RoomV2, listKind: RDListKind) async {
        do {
            switch listKind {
            case .pullList:
                try await RoomRepository<PullListV2>(room: room)
                    .addItems([item.id], toRoomId: room.id, itemRepo: itemRepo)
            case .installedList:
                try await RoomRepository<InstalledListV2>(room: room)
                    .addItems([item.id], toRoomId: room.id, itemRepo: itemRepo)
            }
        } catch let error as ItemAssignmentError {
            handleAssignmentError(error, destinationDocument: room)
        } catch {
            handleAddItemError(.genericError(item: item, destinationDocument: room, error: error))
        }
    }

    func addItemToEssentialsGroup(item: ItemV2, group: EssentialsGroup) async {
        do {
            try await EssentialsRepository().addItems(
                [item.id],
                toGroupId: group.id,
                itemRepo: itemRepo
            )
        } catch let error as ItemAssignmentError {
            handleAssignmentError(error, destinationDocument: group)
        } catch {
            handleAddItemError(.genericError(item: item, destinationDocument: group, error: error))
        }
    }
}

// MARK: - Error Handling

private extension AddItemToDocumentDetailViewModel {
    enum AddItemError: Error {
        case itemUnavailable(_ item: ItemV2)
        case itemAlreadyInDestination(_ item: ItemV2, destinationDocument: any RDDocument)
        case destinationClosed(name: String)
        case genericError(item: ItemV2, destinationDocument: any RDDocument, error: Error)
    }
    
    /// Maps the repository's rejection onto this screen's single-item wording.
    func handleAssignmentError(_ error: ItemAssignmentError, destinationDocument: any RDDocument) {
        switch error {
        case .noEligibleItems(let unavailable, let duplicates):
            if let duplicate = duplicates.first {
                handleAddItemError(.itemAlreadyInDestination(duplicate, destinationDocument: destinationDocument))
            } else if let unavailableItem = unavailable.first {
                handleAddItemError(.itemUnavailable(unavailableItem))
            } else {
                handleAddItemError(.genericError(item: item, destinationDocument: destinationDocument, error: error))
            }
        case .destinationClosed(let name):
            handleAddItemError(.destinationClosed(name: name))
        }
    }

    func handleAddItemError(_ error: AddItemError) {
        switch error {
        case .itemAlreadyInDestination(let item, let destinationDocument):
            alertText = "[ERROR]: Item \(item.displayName) is already assigned to this \(destinationDocument.displayName). Try refreshing."
            showAlert = true
        case .itemUnavailable(let item):
            alertText = "[ERROR]: Item \(item.displayName) is not available to be added. It is currently \(item.location.status.displayTitle)."
            showAlert = true
        case .destinationClosed(let name):
            alertText = "\(name) was uninstalled and no longer accepts items."
            showAlert = true
        case .genericError(let item, let destinationDocument, let error):
            print("[FATAL ERROR]: Failed to add \(item.displayName) to \(destinationDocument.displayName): \(error.localizedDescription)")
            alertText = "[ERROR]: A code error has occurred. "
        }
    }
}
