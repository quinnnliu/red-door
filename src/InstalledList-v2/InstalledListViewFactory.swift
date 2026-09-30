//
//  InstalledListViewFactory.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/25/26.
//

import SwiftUI

struct InstalledListViewFactory {
    private let itemRepo: ItemRepository = ItemRepository()
    private let installedListRepo: InstalledListRepository = InstalledListRepository()
    private let essentialsRepo: EssentialsRepository = EssentialsRepository()
    private let accessoriesRepo: AccessoriesRepository = AccessoriesRepository()
    private let uninstallSessionRepo: UninstallSessionRepository = UninstallSessionRepository()
    private let storageLocationRepo: StorageLocationRepository = StorageLocationRepository()
    private let pullListRepo: PullListRepository = PullListRepository()
    
    func makeItemDetailsView(item: ItemV2, room: RoomV2, uninstalled: Bool) -> InstalledListItemDetailsView {
        let vm = InstalledListItemDetailsViewModel(
            item: item,
            room: room,
            uninstalled: uninstalled,
            roomRepo: RoomRepository(parentCollectionName: InstalledListV2.collectionName, listId: room.listId)
        )
        return InstalledListItemDetailsView(viewModel: vm)
    }

    func makeRoomDetailsView(items: [ItemV2], room: RoomV2, uninstalled: Bool = false) -> InstalledListRoomDetailsView {
        let vm = InstalledListRoomDetailsViewModel(
            room: room,
            roomRepo: RoomRepository(parentCollectionName: InstalledListV2.collectionName, listId: room.listId),
            items: items,
            uninstalled: uninstalled
        )
        return InstalledListRoomDetailsView(viewModel: vm)
    }

    func makeUninstallSheet(list: InstalledListV2) -> UninstallInstalledListSheet {
        let vm = UninstallInstalledListSheetViewModel(
            list: list,
            installedListRepo: installedListRepo,
            installedRoomRepo: RoomRepository(
                parentCollectionName: InstalledListV2.collectionName,
                listId: list.id
            ),
            itemRepo: itemRepo,
            sessionRepo: uninstallSessionRepo,
            pullListRepo: pullListRepo,
            essentialsRepo: essentialsRepo,
            accessoriesRepo: accessoriesRepo,
            storageLocationRepo: storageLocationRepo
        )
        return UninstallInstalledListSheet(viewModel: vm)
    }

    func makeUninstallRecordSheet(list: InstalledListV2) -> UninstallRecordSheet {
        let vm = UninstallRecordSheetViewModel(
            list: list,
            installedRoomRepo: RoomRepository(
                parentCollectionName: InstalledListV2.collectionName,
                listId: list.id
            ),
            itemRepo: itemRepo,
            sessionRepo: uninstallSessionRepo,
            pullListRepo: pullListRepo,
            essentialsRepo: essentialsRepo,
            accessoriesRepo: accessoriesRepo,
            storageLocationRepo: storageLocationRepo
        )
        return UninstallRecordSheet(viewModel: vm)
    }

    func makeDetailsView(list: InstalledListV2) -> InstalledListDetailsViewV2 {
        let vm = InstalledListDetailsViewModelV2(
            list: list,
            installedListRepo: installedListRepo,
            roomRepo: RoomRepository(parentCollectionName: InstalledListV2.collectionName, listId: list.id),
            itemRepo: itemRepo,
            essentialsRepo: essentialsRepo,
            accessoriesRepo: accessoriesRepo
        )
        return InstalledListDetailsViewV2(viewModel: vm)
    }
}
