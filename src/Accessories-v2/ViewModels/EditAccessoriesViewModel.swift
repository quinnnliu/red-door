//
//  EditAccessoriesViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/20/26.
//

import SwiftUI

@Observable
final class EditAccessoriesViewModel {
    private let accessoriesRepo: AccessoriesRepository
    private let accessoriesTypeRepo: AccessoriesTypeRepository
    private let configService: ConfigurationService

    // MARK: - Type Picker State

    var accessoriesTypes: [AccessoriesType] = []
    var showSelectTypeSheet: Bool = false
    var showExistingTypePicker: Bool = false
    var newTypeName: String = ""

    // MARK: - Loading

    var isLoading: Bool = false
    var isDeleting: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""

    init(
        accessoriesRepo: AccessoriesRepository,
        accessoriesTypeRepo: AccessoriesTypeRepository,
        configService: ConfigurationService = .shared
    ) {
        self.accessoriesRepo = accessoriesRepo
        self.accessoriesTypeRepo = accessoriesTypeRepo
        self.configService = configService
    }

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

    func createAndSelectNewType() -> AccessoriesType? {
        let name = newTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let newType = AccessoriesType(baseName: name)
        do {
            try accessoriesTypeRepo.set(document: newType)
            configService.invalidate(AccessoriesType.self)
            accessoriesTypes.append(newType)
            newTypeName = ""
            showSelectTypeSheet = false
            return newType
        } catch {
            print("Error creating accessories type: \(error)")
            return nil
        }
    }

    // MARK: - Delete
    @MainActor
    func deleteAccessories(_ accessories: Accessories) async -> Bool {
        guard accessories.canDelete, !isLoading else { return false }
        isLoading = true
        isDeleting = true
        defer {
            isLoading = false
            isDeleting = false
        }
        do {
            try await accessoriesRepo.deleteAccessories(id: accessories.id)
            return true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
            return false
        }
    }
}
