//
//  WarehouseOptionViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/23/26.
//

import Foundation

@Observable
final class WarehouseOptionViewModel {
    private let warehouseRepo: WarehouseRepository
    private let configService: ConfigurationService

    var warehouses: [WarehouseV2] = []
    var newWarehouse: WarehouseV2 = WarehouseV2(baseName: "", address: Address())
    var warehouseName: String = ""

    var showWarehouseSection: Bool = false
    var editingWarehouses: Bool = false
    var showAddressSheet: Bool = false
    var showWarehouseNameAlert: Bool = false
    var showWarehouseDeleteAlert: Bool = false

    var warehouseAddressExists: Bool {
        warehouses.contains(where: { $0.address.id == newWarehouse.address.id })
    }

    // MARK: init

    init(
        warehouseRepo: WarehouseRepository = WarehouseRepository(),
        configService: ConfigurationService = .shared
    ) {
        self.warehouseRepo = warehouseRepo
        self.configService = configService
    }

    // MARK: - Loading

    func loadWarehouses() async {
        do {
            warehouses = try await configService.getAll(using: warehouseRepo)
        } catch {
            print("Error loading warehouses: \(error.localizedDescription)")
        }
    }

    func refreshWarehouses() async {
        configService.invalidate(WarehouseV2.self)
        await loadWarehouses()
    }

    // MARK: - Adding

    func addWarehouse() {
        let warehouse = WarehouseV2(baseName: warehouseName, address: newWarehouse.address)
        do {
            try warehouseRepo.set(document: warehouse)
            configService.invalidate(WarehouseV2.self)
            warehouses.append(warehouse)
        } catch {
            print("Error adding warehouse: \(error.localizedDescription)")
        }
        showWarehouseNameAlert = false
        newWarehouse = warehouse
    }

    func resetNewWarehouse() {
        newWarehouse = WarehouseV2(baseName: "", address: Address())
    }
}
