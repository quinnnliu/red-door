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

    func makeItemDetailsView(item: ItemV2, room: RoomV2) -> InstalledListItemDetailsView {
        let vm = InstalledListItemDetailsViewModel(
            item: item,
            room: room,
            roomRepo: RoomRepository(parentCollectionName: InstalledListV2.collectionName, listId: room.listId)
        )
        return InstalledListItemDetailsView(viewModel: vm)
    }

    func makeRoomDetailsView(items: [ItemV2], room: RoomV2) -> InstalledListRoomDetailsView {
        let vm = InstalledListRoomDetailsViewModel(
            room: room,
            roomRepo: RoomRepository(parentCollectionName: InstalledListV2.collectionName, listId: room.listId),
            items: items
        )
        return InstalledListRoomDetailsView(viewModel: vm)
    }

    func makeDetailsView(list: InstalledListV2) -> InstalledListDetailsViewV2 {
        let vm = InstalledListDetailsViewModelV2(
            list: list,
            installedListRepo: installedListRepo,
            roomRepo: RoomRepository(parentCollectionName: InstalledListV2.collectionName, listId: list.id),
            itemRepo: itemRepo
        )
        return InstalledListDetailsViewV2(viewModel: vm)
    }
}
