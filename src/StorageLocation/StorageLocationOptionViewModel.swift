//
//  StorageLocationOptionsViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/23/26.
//

import Foundation

@Observable
final class StorageLocationOptionsViewModel {
    private let storageLocationRepo: StorageLocationRepository
    private let configService: ConfigurationService

    var storageLocations: [StorageLocation] = []
    var newStorageLocation: StorageLocation = StorageLocation(baseName: "", address: Address())
    var storageLocationName: String = ""

    var showStorageLocationSection: Bool = false
    var editingStorageLocations: Bool = false
    var showAddressSheet: Bool = false
    var showStorageLocationNameAlert: Bool = false
    var showStorageLocationDeleteAlert: Bool = false

    var storageLocationAddressExists: Bool {
        storageLocations.contains(where: { $0.address.id == newStorageLocation.address.id })
    }

    // MARK: init

    init(
        storageLocationRepo: StorageLocationRepository = StorageLocationRepository(),
        configService: ConfigurationService = .shared
    ) {
        self.storageLocationRepo = storageLocationRepo
        self.configService = configService
    }

    // MARK: - Loading

    func loadStorageLocations() async {
        do {
            storageLocations = try await configService.getAll(using: storageLocationRepo)
        } catch {
            print("Error loading storage locations: \(error.localizedDescription)")
        }
    }

    func refreshStorageLocations() async {
        configService.invalidate(StorageLocation.self)
        await loadStorageLocations()
    }

    // MARK: - Adding

    func addStorageLocation() {
        let name = storageLocationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            showStorageLocationNameAlert = false
            return
        }

        let storageLocation = StorageLocation(baseName: name, address: newStorageLocation.address)
        do {
            try storageLocationRepo.set(document: storageLocation)
            configService.invalidate(StorageLocation.self)
            storageLocations.append(storageLocation)
        } catch {
            print("Error adding storage location: \(error.localizedDescription)")
        }
        showStorageLocationNameAlert = false
        newStorageLocation = storageLocation
    }

    func resetStorageLocation() {
        newStorageLocation = StorageLocation(baseName: "", address: Address())
    }
}
