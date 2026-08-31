//
//  EssentialsViewFactory.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/30/26.
//

import SwiftUI

struct EssentialsViewFactory {
    private let essentialsRepo = EssentialsRepository()
    private let essentialsGroupTypeRepo = EssentialsGroupTypeRepository()

    func makeCreateEssentialsGroupView() -> CreateEssentialsGroupView {
        let vm = CreateEssentialsGroupViewModel(
            essentialsRepo: essentialsRepo,
            essentialsGroupTypeRepo: essentialsGroupTypeRepo
        )
        return CreateEssentialsGroupView(viewModel: vm)
    }
}
