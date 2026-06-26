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

    // MARK: - Group Type
    var groupTypes: [EssentialsGroupType] = []
    var selectedGroupType: EssentialsGroupType?
    var newGroupTypeName: String = ""
    var showNewTypeField: Bool = false
    var showGroupTypePicker: Bool = false

    // MARK: - Accessories
    var selectedAccessory: Accessories? = nil
    var showAddAccessoriesSheet: Bool = false

    // MARK: - State
    var isLoading: Bool = false
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
            accessoriesId: selectedAccessory?.id
        )

        isLoading = true
        defer { isLoading = false }

        do {
            try essentialsRepo.set(document: group)
            return true
        } catch {
            print("Error creating essentials group: \(error)")
            return false
        }
    }

    // MARK: - Accessories

    func clearAccessory() {
        selectedAccessory = nil
    }
}
