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
    private let essentialsRepo: EssentialsRepository = .init()
    var essentialsGroup: EssentialsGroup?

    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertText: String = ""
    /// The destination list or room is gone or closed; the view presents it.
    var staleWriteError: StaleWriteError? = nil

    init(item: ItemV2, destination: AddItemsToListableDestination) {
        self.item = item
        self.destination = destination
    }
}

// MARK: - Load Essentials Group

extension AddItemToDocumentDetailViewModel {
    func loadEssentialsGroup() async {
        guard let groupId = item.essentialGroupId else { return }
        do { essentialsGroup = try await essentialsRepo.get(id: groupId) }
        catch { print("error loading essentials group: \(error)") }
    }
}

// MARK: - Add Item

extension AddItemToDocumentDetailViewModel {
    func addItem() async {
        isLoading = true
        defer { isLoading = false }

        switch destination {
        case .room(let room, let listType):
            await addItemToRoom(item: item, room: room, listType: listType)
        case .essentialsGroup(let group):
            await addItemToEssentialsGroup(item: item, group: group)
        }
    }
}

// MARK: - Private Assignment Methods

private extension AddItemToDocumentDetailViewModel {

    /// The switch erases `listType` back into a concrete `RoomRepository`
    /// parameter, which is what picks the collection and the item's new status.
    func addItemToRoom(item: ItemV2, room: RoomV2, listType: RDListType) async {
        do {
            switch listType {
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
            handleTransactionFailure(error, destinationDocument: room)
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
            handleTransactionFailure(error, destinationDocument: group)
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
        }
    }

    func handleTransactionFailure(_ error: Error, destinationDocument: any RDDocument) {
        if let stale = StaleWriteError(error) {
            staleWriteError = stale
        } else {
            handleAddItemError(.genericError(item: item, destinationDocument: destinationDocument, error: error))
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
        case .genericError(let item, let destinationDocument, let error):
            print("[FATAL ERROR]: Failed to add \(item.displayName) to \(destinationDocument.displayName): \(error.localizedDescription)")
            alertText = "[ERROR]: A code error has occurred. "
        }
    }
}
