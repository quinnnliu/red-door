//
//  CreateEssentialsGroupViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import SwiftUI

@Observable
final class CreateEssentialsGroupViewModel {
    private let essentialsRepo: EssentialsRepository = .init()
    private let essentialsGroupTypeRepo: EssentialsGroupTypeRepository = .init()
    private let itemRepo: ItemRepository = .init()

    // MARK: - Group Type
    var groupTypes: [EssentialsGroupType] = []
    var selectedGroupType: EssentialsGroupType?
    var newGroupTypeName: String = ""
    var showNewTypeField: Bool = false
    var showGroupTypePicker: Bool = false

    var selectedItemIds: Set<String> = []
    var selectedItems: [ItemV2] = []
    var showItemPickerSheet: Bool = false

    var selectedAccessory: Accessories? = nil
    var showAccessoriesPickerSheet: Bool = false

    var isLoading: Bool = false
    var showAddAccessoriesSheet: Bool = false
    
    var showAlert: Bool = false
    var alertText: String = ""

    // MARK: - Load

    func loadGroupTypes() async {
        do {
            groupTypes = try await essentialsGroupTypeRepo.getAll()
        } catch {
            print("Error loading group types: \(error)")
        }
    }

    // MARK: - Create Group Type

    func createAndSelectNewGroupType() async {
        let name = newGroupTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let newType = EssentialsGroupType(displayName: name)

        do {
            try essentialsGroupTypeRepo.set(document: newType)
            groupTypes.append(newType)
            selectedGroupType = newType
            newGroupTypeName = ""
            showNewTypeField = false
        } catch {
            print("Error creating group type: \(error)")
        }
    }

    // MARK: - Create Essentials Group

    func createEssentialsGroup() async -> Bool {
        guard let groupType = selectedGroupType else { return false }

        let group = EssentialsGroup(
            displayName: groupType.displayName,
            essentialsTypeId: groupType.id,
            itemIds: Array(selectedItemIds),
            accessoriesId: selectedAccessory?.id
        )

        isLoading = true
        defer { isLoading = false }

        do {
            let _ = try await essentialsRepo.db.runTransaction({ (transaction, errorPointer) -> Any? in
                do {
                    let groupItems = try self.itemRepo.get(
                        ids: group.itemIds,
                        transaction: transaction
                    )

                    if let installedItem = groupItems.first(where: { $0.status == .inInstalledList }) {
                        throw CreateEssentialsError.itemInstalled(installedItem.displayName)
                    }

                    for item in groupItems {
                        self.itemRepo.update(
                            id: item.id,
                            fields: [ItemV2.CodingKeys.essentialGroupId.stringValue: group.id],
                            transaction: transaction
                        )
                    }

                    try self.essentialsRepo.set(
                        document: group,
                        id: group.id,
                        transaction: transaction
                    )

                    return nil
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            })
            return true
        } catch let error as CreateEssentialsError {
            if case .itemInstalled(let name) = error {
                alertText = "Item \"\(name)\" is currently installed and cannot be added to an essentials group."
                showAlert = true
            }
            return false
        } catch {
            print("Error creating essentials group: \(error)")
            return false
        }
    }

    // MARK: - Selection Helpers

    func addItem(_ item: ItemV2) {
        guard !selectedItemIds.contains(item.id) else { return }
        selectedItemIds.insert(item.id)
        selectedItems.append(item)
    }

    func removeItem(_ item: ItemV2) {
        selectedItemIds.remove(item.id)
        selectedItems.removeAll { $0.id == item.id }
    }

    func clearAccessory() {
        selectedAccessory = nil
    }
}

extension CreateEssentialsGroupViewModel {
    enum CreateEssentialsError: Error {
        case itemInstalled(String)
    }
}
