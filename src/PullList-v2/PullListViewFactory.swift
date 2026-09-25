//
//  PullListViewFactory.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/23/26.
//

import SwiftUI

struct PullListViewFactory {
    private let itemRepo: ItemRepository = ItemRepository()
    private let pullListRepo: PullListRepository = PullListRepository()
    private let essentialsRepo: EssentialsRepository = EssentialsRepository()
    private let accessoriesRepo: AccessoriesRepository = AccessoriesRepository()

    func makeDetailsView(list: PullListV2) -> PullListDetailsViewV2 {
        let vm = PullListDetailsViewModelV2(
            list: list,
            roomRepo: RoomRepository(list: list),
            itemRepo: itemRepo,
            pullListRepo: pullListRepo,
            essentialsRepo: essentialsRepo,
            accessoriesRepo: accessoriesRepo
        )
        return PullListDetailsViewV2(viewModel: vm)
    }
}
