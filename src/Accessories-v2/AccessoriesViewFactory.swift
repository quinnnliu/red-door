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

    func makeCreateAccessoriesView() -> CreateAccessoriesView {
        let vm = CreateAccessoriesViewModel(
            accessoriesRepo: accessoriesRepo,
            accessoriesTypeRepo: accessoriesTypeRepo
        )
        return CreateAccessoriesView(viewModel: vm)
    }
}
