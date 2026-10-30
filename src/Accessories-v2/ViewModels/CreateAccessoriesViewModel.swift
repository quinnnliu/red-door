//
//  CreateAccessoriesViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import SwiftUI

@Observable
final class CreateAccessoriesViewModel {
    private let accessoriesRepo: AccessoriesRepository
    private let accessoriesTypeRepo: AccessoriesTypeRepository
    private let storageLocationRepo: StorageLocationRepository
    private let configService: ConfigurationService

    private let accessoryId: String

    init(
        accessoriesRepo: AccessoriesRepository,
        accessoriesTypeRepo: AccessoriesTypeRepository,
        storageLocationRepo: StorageLocationRepository,
        configService: ConfigurationService = .shared
    ) {
        self.accessoriesRepo = accessoriesRepo
        self.accessoriesTypeRepo = accessoriesTypeRepo
        self.storageLocationRepo = storageLocationRepo
        self.configService = configService
        let accessoryId = UUID().uuidString
        self.accessoryId = accessoryId
        self.primaryImage = .empty(for: accessoryId)
    }

    // MARK: - Type

    var accessoriesTypes: [AccessoriesType] = []
    var selectedType: AccessoriesType?
    var newTypeName: String = ""
    var showNewTypeField: Bool = false
    var showExistingTypePicker: Bool = false
    var showSelectTypeSheet: Bool = false

    // MARK: - Storage Location

    var storageLocations: [StorageLocation] = []
    var selectedStorageLocation: StorageLocation?


    // MARK: - Fields

    var nickname: String = ""
    var description: String = ""
    var primaryImage: RDImage

    // MARK: - Image

    func setPrimaryImage(_ uiImage: UIImage) {
        primaryImage = RDImage(uiImage: uiImage, documentId: accessoryId)
    }

    func clearPrimaryImage() {
        primaryImage = .empty(for: accessoryId)
    }

    // MARK: - State

    var isLoading: Bool = false

    // MARK: - Load

    func loadTypes() async {
        do {
            accessoriesTypes = try await configService.getAll(using: accessoriesTypeRepo)
        } catch {
            print("Error loading accessories types: \(error)")
        }
    }

    func refreshTypes() async {
        configService.invalidate(AccessoriesType.self)
        await loadTypes()
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

    // MARK: - Create Type

    func createAndSelectNewType() {
        let name = newTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let newType = AccessoriesType(baseName: name)
        do {
            try accessoriesTypeRepo.set(document: newType)
            configService.invalidate(AccessoriesType.self)
            accessoriesTypes.append(newType)
            selectedType = newType
            newTypeName = ""
            showNewTypeField = false
            showSelectTypeSheet = false
        } catch {
            print("Error creating accessories type: \(error)")
        }
    }

    // MARK: - Create Accessories

    func createAccessories() async -> Bool {
        guard let type = selectedType,
              let storageLocation = selectedStorageLocation else { return false }

        isLoading = true
        defer { isLoading = false }

        do {
            let maxNumber = await accessoriesRepo.maxAccessoriesNumber(forTypeId: type.id)
            let (persistedImage, _) = try await FirebaseImageManager.shared.resolveImage(
                original: nil,
                updated: primaryImage,
                type: .accessory
            )
            let newAccessory = Accessories(
                id: accessoryId,
                baseName: type.displayName,
                accessoriesTypeId: type.id,
                primaryImage: persistedImage ?? .empty(for: accessoryId),
                location: DocumentLocation(status: .inStorage, locationId: storageLocation.id),
                description: description,
                accessoriesNumber: maxNumber + 1,
                nickname: nickname.isEmpty ? nil : nickname
            )

            try accessoriesRepo.set(document: newAccessory)
            return true
        } catch {
            print("Error creating accessory: \(error)")
            return false
        }
    }
}
