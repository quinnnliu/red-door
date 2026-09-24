enum AddItemsToListableDestination: Hashable {
    case room(RoomV2)
    case essentialsGroup(EssentialsGroup)

    var document: any ItemsListableDocument {
        switch self {
        case .room(let room): return room
        case .essentialsGroup(let group): return group
        }
    }
}

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
    case essentialsGroupDetailView(_ group: EssentialsGroup, emoji: String)

    // MARK: Accessories
    case accessoriesDetailView(_ accessories: Accessories)

    // MARK: Generic Add Item
    case addItemToDocumentDetailView(item: ItemV2, destination: AddItemsToListableDestination)
}

