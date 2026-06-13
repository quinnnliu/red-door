//
//  CreateAccessoriesViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import SwiftUI

@Observable
final class CreateAccessoriesViewModel {
    private let accessoriesRepo: AccessoriesRepository = .init()
    private let accessoriesTypeRepo: AccessoriesTypeRepository = .init()

    var displayName: String = ""
    var description: String = ""
    var selectedType: AccessoriesType?
    var existingTypes: [AccessoriesType] = []
    var newTypeName: String = ""
    var primaryImage: RDImage = RDImage()
    var secondaryImages: [RDImage]? = nil

    var isLoading: Bool = false

    // MARK: - Load

    func loadTypes() async {
        // TODO: use DocumentListViewModelV2<AccessoriesType> or a one-shot fetch
    }

    // MARK: - createAccessories

    func createAccessories() async {
        guard let accessoriesType = selectedType else { return }

        let accessory = Accessories(
            displayName: displayName,
            accessoriesTypeId: accessoriesType.id,
            primaryImage: primaryImage,
            secondaryImages: secondaryImages,
            description: description
        )

        isLoading = true
        defer { isLoading = false }

        do {
            try accessoriesRepo.set(document: accessory)
        } catch {
            print("Error creating accessory: \(error)")
        }
    }
}
