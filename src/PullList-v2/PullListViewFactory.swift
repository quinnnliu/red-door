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

    /// Rooms come from the installed list's own subcollection, so the repo is
    /// built against `installed_list_v2` rather than the pull list default.
    func makeCopyFromInstalledView(
        installedList: InstalledListV2,
        onFinished: @escaping () -> Void
    ) -> CopyFromInstalledListView {
        let vm = CopyFromInstalledListViewModel(
            installedList: installedList,
            installedRoomRepo: RoomRepository(
                parentCollectionName: InstalledListV2.collectionName,
                listId: installedList.id
            ),
            itemRepo: itemRepo,
            pullListRepo: pullListRepo,
            essentialsRepo: essentialsRepo,
            accessoriesRepo: accessoriesRepo
        )
        return CopyFromInstalledListView(viewModel: vm, onFinished: onFinished)
    }
}
