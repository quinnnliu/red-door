//
//  AddItemToDocumentSheetViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/24/26.
//

import Foundation

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
        case .room(let room, let listKind):
            return await addItemsToRoom(items: selectedItems, room: room, listKind: listKind)
        case .essentialsGroup(let group):
            return await addItemsToEssentialsGroup(items: selectedItems, group: group)
        }
    }
}

// MARK: - Private Assignment Methods

private extension AddItemToDocumentSheetViewModel {

    /// The switch erases `listKind` back into a concrete `RoomRepository`
    /// parameter. Both branches are the same call; only the parent type
    /// differs, and that's what picks the collection and the item's new status.
    func addItemsToRoom(items: Set<ItemV2>, room: RoomV2, listKind: RDListKind) async -> Bool {
        let itemIds = items.map(\.id)
        do {
            switch listKind {
            case .pullList:
                try await RoomRepository<PullListV2>(room: room)
                    .addItems(itemIds, toRoomId: room.id, itemRepo: itemRepo)
            case .installedList:
                try await RoomRepository<InstalledListV2>(room: room)
                    .addItems(itemIds, toRoomId: room.id, itemRepo: itemRepo)
            }
            return true
        } catch let error as ItemAssignmentError {
            handleError(error)
            return false
        } catch {
            handleError(AddItemsError.transactionFailed(error))
            return false
        }
    }

    func addItemsToEssentialsGroup(items: Set<ItemV2>, group: EssentialsGroup) async -> Bool {
        do {
            try await EssentialsRepository().addItems(
                items.map(\.id),
                toGroupId: group.id,
                itemRepo: itemRepo
            )
            return true
        } catch let error as ItemAssignmentError {
            handleError(error)
            return false
        } catch {
            handleError(AddItemsError.transactionFailed(error))
            return false
        }
    }
}

// MARK: - Error Handling

private extension AddItemToDocumentSheetViewModel {
    enum AddItemsError: Error {
        case noValidItems(unavailable: [String], duplicates: [String])
        case destinationClosed(name: String)
        case transactionFailed(Error)
    }

    /// Maps the repository's rejection onto this screen's grouped wording.
    func handleError(_ error: ItemAssignmentError) {
        switch error {
        case .noEligibleItems(let unavailable, let duplicates):
            handleError(
                AddItemsError.noValidItems(
                    unavailable: unavailable.map(\.displayName),
                    duplicates: duplicates.map(\.displayName)
                )
            )
        case .destinationClosed(let name):
            handleError(AddItemsError.destinationClosed(name: name))
        }
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
        case .destinationClosed(let name):
            alertText = "\(name) was uninstalled and no longer accepts items."
            showAlert = true
        case .transactionFailed(let error):
            print("[FATAL ERROR]: Failed to add items to \(destination.document.displayName): \(error.localizedDescription)")
            alertText = "[ERROR]: A code error has occurred."
            showAlert = true
        }
    }
}
