//
//  EditAccessoriesViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/20/26.
//

import SwiftUI

@Observable
final class EditAccessoriesViewModel {
    private let accessoriesTypeRepo: AccessoriesTypeRepository
    private let configService: ConfigurationService

    // MARK: - Type Picker State

    var accessoriesTypes: [AccessoriesType] = []
    var showSelectTypeSheet: Bool = false
    var showExistingTypePicker: Bool = false
    var newTypeName: String = ""

    // MARK: - Loading

    var isLoading: Bool = false

    init(
        accessoriesTypeRepo: AccessoriesTypeRepository,
        configService: ConfigurationService = .shared
    ) {
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
}
