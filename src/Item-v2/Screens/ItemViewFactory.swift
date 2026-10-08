//
//  ItemViewFactory.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/4/26.
//

import SwiftUI

struct ItemViewFactory {
    private let itemRepo = ItemRepository()
    private let essentialsRepo = EssentialsRepository()

    func makeItemDetailsView(item: ItemV2) -> ItemDetailsViewV2 {
        let vm = ItemDetailViewModel(
            item: item,
            itemRepo: itemRepo,
            essentialsRepo: essentialsRepo
        )
        return ItemDetailsViewV2(viewModel: vm)
    }

    func makePDFView(item: ItemV2) -> ItemV2PDFView {
        let vm = ItemV2PDFViewModel(
            item: item,
            storageLocationRepo: StorageLocationRepository(),
            pullListRepo: PullListRepository(),
            installedListRepo: InstalledListRepository()
        )
        return ItemV2PDFView(viewModel: vm)
    }

    func makeEditItemView(
        item: ItemV2,
        essentialsGroup: EssentialsGroup?,
        onDelete: (() -> Void)? = nil
    ) -> EditItemView {
        let vm = EditItemViewModel(
            item: item,
            essentialsGroup: essentialsGroup,
            itemRepo: itemRepo,
            essentialsRepo: essentialsRepo
        )
        return EditItemView(viewModel: vm, onDelete: onDelete)
    }
}
