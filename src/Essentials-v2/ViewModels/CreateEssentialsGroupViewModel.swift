//
//  CreateEssentialsGroupViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import SwiftUI

@Observable
final class CreateEssentialsGroupViewModel {
    private let essentialsRepo: EssentialsRepository
    private let essentialsGroupTypeRepo: EssentialsGroupTypeRepository
    private let configService: ConfigurationService

    init(
        essentialsRepo: EssentialsRepository,
        essentialsGroupTypeRepo: EssentialsGroupTypeRepository,
        configService: ConfigurationService = .shared
    ) {
        self.essentialsRepo = essentialsRepo
        self.essentialsGroupTypeRepo = essentialsGroupTypeRepo
        self.configService = configService
    }

    // MARK: - Group Type
    var groupTypes: [EssentialsGroupType] = []
    var selectedGroupType: EssentialsGroupType?
    var newGroupTypeName: String = ""
    var showNewTypeField: Bool = false
    var showGroupTypePicker: Bool = false

    // MARK: - Accessories
    var selectedAccessory: Accessories? = nil
    var showAddAccessoriesSheet: Bool = false

    // MARK: - Nickname
    var nickname: String = ""

    // MARK: - State
    var isLoading: Bool = false
    var showAlert: Bool = false
    var alertText: String = ""

    // MARK: - Load

    func loadGroupTypes() async {
        do {
            groupTypes = try await configService.getAll(using: essentialsGroupTypeRepo)
        } catch {
            print("Error loading group types: \(error)")
        }
    }

    // MARK: - Create Group Type

    func createAndSelectNewGroupType() {
        let name = newGroupTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let newType = EssentialsGroupType(displayName: name)

        do {
            try essentialsGroupTypeRepo.set(document: newType)
            configService.invalidate(EssentialsGroupType.self)
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

        isLoading = true
        defer { isLoading = false }

        do {
            let maxNumber =  await essentialsRepo.maxGroupNumber(forTypeId: groupType.id)
            let group = EssentialsGroup(
                displayName: groupType.displayName,
                essentialsTypeId: groupType.id,
                accessoriesId: selectedAccessory?.id,
                groupNumber: maxNumber + 1,
                nickname: nickname.isEmpty ? nil : nickname
            )
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
