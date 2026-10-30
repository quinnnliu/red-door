enum AddItemsToListableDestination: Hashable {
    case room(RoomV2, listType: RDListType)
    case essentialsGroup(EssentialsGroup)

    var document: any ItemsListableDocument {
        switch self {
        case .room(let room, _): return room
        case .essentialsGroup(let group): return group
        }
    }
}

enum NavigationDestination: Hashable {
    // MARK: Item
    case itemDetailView(_ item: ItemV2)
    case pullListItemDetailView(item: ItemV2, room: RoomV2)
    case installedListItemDetailView(item: ItemV2, room: RoomV2, uninstalled: Bool)

    // MARK: PullList
    case pullListDetailView(_ list: PullListV2, essentialsGroupNavigable: Bool = true)

    // MARK: InstalledList
    case installedListDetailView(_ list: InstalledListV2, essentialsGroupNavigable: Bool = true)

    // MARK: Room
    case pulllistRoomDetailView(items: [ItemV2], room: RoomV2)
    case installedListRoomDetailView(items: [ItemV2], room: RoomV2, uninstalled: Bool)

    // MARK: EssentialsGroup
    case essentialsGroupDetailView(_ group: EssentialsGroup, locationNavigable: Bool = true)

    // MARK: Accessories
    case accessoriesDetailView(_ accessories: Accessories, locationNavigable: Bool = true)

    // MARK: Generic Add Item
    case addItemToDocumentDetailView(item: ItemV2, destination: AddItemsToListableDestination)
}

