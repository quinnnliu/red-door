enum NavigationDestination: Hashable {
    // MARK: Item
    case itemDetailView(_ item: ItemV2)
    case addItemToRoomDetailView(_ item: ItemV2, room: RoomV2)
    case pullListItemDetailView(item: ItemV2, room: RoomV2)

    // MARK: PullList
    case pullListDetailView(_ list: PullListV2)
    
    // MARK: InstalledList
    case installedListDetailView(_ list: InstalledListV2)

    // MARK: Room
    case pulllistRoomDetailView(items: [ItemV2], room: RoomV2)

    // MARK: EssentialsGroup
    case essentialsGroupDetailView(_ group: EssentialsGroup)

    // MARK: Accessories
    case accessoriesDetailView(_ accessories: Accessories)

    // MARK: Generic Add Item
    case addItemToDocumentDetailView(context: AddItemDocumentContext)
}

