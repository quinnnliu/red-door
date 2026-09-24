//
//  PullListV2ViewFactory.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/23/26.
//

import SwiftUI

struct PullListV2ViewFactory {
    private let itemRepo: ItemRepository = ItemRepository()
    private let pullListRepo: PullListRepository = PullListRepository()
    private let essentialsRepo: EssentialsRepository = EssentialsRepository()
    private let accessoriesRepo: AccessoriesRepository = AccessoriesRepository()

    func makeDetailsView(list: PullListV2) -> PullListV2DetailsView {
        let vm = PullListV2DetailsViewModel(
            list: list,
            roomRepo: RoomRepository(list: list),
            itemRepo: itemRepo,
            pullListRepo: pullListRepo,
            essentialsRepo: essentialsRepo,
            accessoriesRepo: accessoriesRepo
        )
        return PullListV2DetailsView(viewModel: vm)
    }
}
