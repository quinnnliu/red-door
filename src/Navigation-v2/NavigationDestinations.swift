enum NavigationDestination: Hashable {
        // MARK: Item
    case itemDetailView(_ item: ItemV2)
    case addItemToRoomDetailView(_ item: ItemV2, room: RoomV2)
    case pullListItemDetailView(item: ItemV2, room: RoomV2, rooms: [RoomV2], list: PullListV2)
    
        // MARK: PullList
    case pullListDetailView(_ list: PullListV2)
    
        // MARK: Room
    case roomDetailView(items: [ItemV2], room: RoomV2)
    case roomItemDetailView(item: ItemV2, room: RoomV2)
}

