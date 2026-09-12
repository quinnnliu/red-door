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
    private let configService: ConfigurationService

    init(
        accessoriesRepo: AccessoriesRepository,
        accessoriesTypeRepo: AccessoriesTypeRepository,
        configService: ConfigurationService = .shared
    ) {
        self.accessoriesRepo = accessoriesRepo
        self.accessoriesTypeRepo = accessoriesTypeRepo
        self.configService = configService
    }

    // MARK: - Type

    var accessoriesTypes: [AccessoriesType] = []
    var selectedType: AccessoriesType?
    var newTypeName: String = ""
    var showNewTypeField: Bool = false
    var showTypePicker: Bool = false

    // MARK: - Fields

    var nickname: String = ""
    var description: String = ""
    var primaryImage: RDImage = RDImage()

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

    // MARK: - Create Type

    func createAndSelectNewType() {
        let name = newTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let newType = AccessoriesType(displayName: name)
        do {
            try accessoriesTypeRepo.set(document: newType)
            configService.invalidate(AccessoriesType.self)
            accessoriesTypes.append(newType)
            selectedType = newType
            newTypeName = ""
            showNewTypeField = false
        } catch {
            print("Error creating accessories type: \(error)")
        }
    }

    // MARK: - Create Accessories

    func createAccessories() async -> Bool {
        guard let type = selectedType else { return false }

        isLoading = true
        defer { isLoading = false }

        do {
            let maxNumber = await accessoriesRepo.maxAccessoriesNumber(forTypeId: type.id)
            var newAccessory = Accessories(
                displayName: type.displayName,
                accessoriesTypeId: type.id,
                primaryImage: primaryImage,
                description: description,
                accessoriesNumber: maxNumber + 1,
                nickname: nickname.isEmpty ? nil : nickname
            )
            newAccessory.primaryImage.objectId = newAccessory.id

            if let uploadedImage = try await FirebaseImageManager.shared.updateImage(
                newAccessory.primaryImage,
                resultImageType: .accessory
            ) {
                newAccessory.primaryImage = uploadedImage
            }

            try accessoriesRepo.set(document: newAccessory)
            return true
        } catch {
            print("Error creating accessory: \(error)")
            return false
        }
    }
}
