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
    private let storageLocationRepo: StorageLocationRepository
    private let accessoriesRepo: AccessoriesRepository
    private let configService: ConfigurationService

    init(
        essentialsRepo: EssentialsRepository,
        essentialsGroupTypeRepo: EssentialsGroupTypeRepository,
        storageLocationRepo: StorageLocationRepository,
        accessoriesRepo: AccessoriesRepository,
        configService: ConfigurationService = .shared
    ) {
        self.essentialsRepo = essentialsRepo
        self.essentialsGroupTypeRepo = essentialsGroupTypeRepo
        self.storageLocationRepo = storageLocationRepo
        self.accessoriesRepo = accessoriesRepo
        self.configService = configService
    }

    // MARK: - Group Type
    var groupTypes: [EssentialsGroupType] = []
    var selectedGroupType: EssentialsGroupType?
    var newGroupTypeName: String = ""
    var newGroupTypeEmoji: String = ""
    var showNewTypeField: Bool = false
    var showGroupTypePicker: Bool = false

    var newGroupTypeValid: Bool {
        let name = newGroupTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && (newGroupTypeEmoji.isEmpty || newGroupTypeEmoji.isSingleEmoji)
    }

    var showConfirmNewTypeAlert: Bool = false

    /// An existing group type whose name matches the name entered for a new type.
    var existingTypeMatchingNewName: EssentialsGroupType? {
        let name = EssentialsGroupType.normalizeSearchText(newGroupTypeName.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !name.isEmpty else { return nil }
        return groupTypes.first { EssentialsGroupType.normalizeSearchText($0.baseName) == name }
    }

    func selectExistingTypeMatchingNewName() {
        guard let existing = existingTypeMatchingNewName else { return }
        selectedGroupType = existing
        newGroupTypeName = ""
        newGroupTypeEmoji = ""
        showNewTypeField = false
    }

    // MARK: - Storage Location
    var storageLocations: [StorageLocation] = []
    var selectedStorageLocation: StorageLocation?

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

    func refreshGroupTypes() async {
        configService.invalidate(EssentialsGroupType.self)
        await loadGroupTypes()
    }

    // MARK: - Load Storage Locations

    func loadStorageLocations() async {
        do {
            storageLocations = try await configService.getAll(using: storageLocationRepo)
            if selectedStorageLocation == nil, storageLocations.count == 1 {
                selectedStorageLocation = storageLocations.first
            }
        } catch {
            print("Error loading storage locations: \(error)")
        }
    }

    func refreshStorageLocations() async {
        configService.invalidate(StorageLocation.self)
        await loadStorageLocations()
    }

    // MARK: - Create Group Type

    func createAndSelectNewGroupType() {
        let name = newGroupTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let emoji = newGroupTypeEmoji.isSingleEmoji ? newGroupTypeEmoji : "⭐️"
        let newType = EssentialsGroupType(baseName: name, emoji: emoji)

        do {
            try essentialsGroupTypeRepo.set(document: newType)
            configService.invalidate(EssentialsGroupType.self)
            groupTypes.append(newType)
            selectedGroupType = newType
            newGroupTypeName = ""
            newGroupTypeEmoji = ""
            showNewTypeField = false
        } catch {
            print("Error creating group type: \(error)")
        }
    }

    // MARK: - Create Essentials Group

    func createEssentialsGroup() async -> Bool {
        guard let groupType = selectedGroupType,
              let storageLocation = selectedStorageLocation else { return false }

        isLoading = true
        defer { isLoading = false }

        do {
            let maxNumber =  await essentialsRepo.maxGroupNumber(forTypeId: groupType.id)
            let group = EssentialsGroup(
                baseName: groupType.displayName,
                location: DocumentLocation(status: .inStorage, locationId: storageLocation.id),
                essentialsTypeId: groupType.id,
                emoji: groupType.emoji,
                accessoriesId: selectedAccessory?.id,
                groupNumber: maxNumber + 1,
                nickname: nickname.isEmpty ? nil : nickname
            )
            let batch = essentialsRepo.db.batch()
            try essentialsRepo.set(document: group, id: group.id, inBatch: batch)
            if let accessory = selectedAccessory {
                accessoriesRepo.update(
                    id: accessory.id,
                    fields: [Accessories.CodingKeys.essentialsGroupId.stringValue: group.id],
                    inBatch: batch
                )
            }
            try await batch.commit()
            return true
        } catch {
            print("Error creating essentials group: \(error)")
            return false
        }
    }

    // MARK: - Accessories

    func selectAccessory(_ accessories: Accessories) {
        selectedAccessory = accessories
    }

    func clearAccessory() {
        selectedAccessory = nil
    }
}
