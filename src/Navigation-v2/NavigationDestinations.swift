enum AddItemsToListableDestination: Hashable {
    /// `listKind` is what tells the add path which collection the room lives
    /// in. Derive it from the list type (`InstalledListV2.listKind`) rather
    /// than writing the case by hand.
    case room(RoomV2, listKind: RDListKind)
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
    case addItemToRoomDetailView(_ item: ItemV2, room: RoomV2)
    case pullListItemDetailView(item: ItemV2, room: RoomV2)
    case installedListItemDetailView(item: ItemV2, room: RoomV2, uninstalled: Bool)

    // MARK: PullList
    case pullListDetailView(_ list: PullListV2)
    
    // MARK: InstalledList
    case installedListDetailView(_ list: InstalledListV2)

    // MARK: Room
    case pulllistRoomDetailView(items: [ItemV2], room: RoomV2)
    case installedListRoomDetailView(items: [ItemV2], room: RoomV2, uninstalled: Bool)

    // MARK: EssentialsGroup
    case essentialsGroupDetailView(_ group: EssentialsGroup)

    // MARK: Accessories
    case accessoriesDetailView(_ accessories: Accessories)

    // MARK: Generic Add Item
    case addItemToDocumentDetailView(item: ItemV2, destination: AddItemsToListableDestination)
}

