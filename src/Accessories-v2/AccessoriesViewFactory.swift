//
//  AccessoriesViewFactory.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/29/26.
//

import SwiftUI

struct AccessoriesViewFactory {
    private let accessoriesRepo = AccessoriesRepository()
    private let accessoriesTypeRepo = AccessoriesTypeRepository()
    private let storageLocationRepo = StorageLocationRepository()

    func makeCreateAccessoriesView() -> CreateAccessoriesView {
        let vm = CreateAccessoriesViewModel(
            accessoriesRepo: accessoriesRepo,
            accessoriesTypeRepo: accessoriesTypeRepo,
            storageLocationRepo: storageLocationRepo
        )
        return CreateAccessoriesView(viewModel: vm)
    }

    func makeAccessoriesDetailsView(accessories: Accessories, locationNavigable: Bool = true) -> AccessoriesDetailsView {
        AccessoriesDetailsView(accessories: accessories, locationNavigable: locationNavigable)
    }

    func makeEditAccessoriesSheet(
        accessories: Accessories,
        onSave: @escaping (Accessories) -> Void,
        onDelete: @escaping () -> Void = {}
    ) -> EditAccessoriesSheet {
        let vm = EditAccessoriesViewModel(
            accessoriesRepo: accessoriesRepo,
            accessoriesTypeRepo: accessoriesTypeRepo
        )
        return EditAccessoriesSheet(
            accessories: accessories,
            viewModel: vm,
            accessoriesRepo: accessoriesRepo,
            onSave: onSave,
            onDelete: onDelete
        )
    }
}
