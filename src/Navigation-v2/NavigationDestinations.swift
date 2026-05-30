enum NavigationDestination: Hashable {
    case roomDetailView(room: RoomV2, list: PullListV2)
    case itemDetailView(_ item: ItemV2)
    case pullListDetailView(_ list: PullListV2)
    case pullListItemDetailView(item: ItemV2, list: PullListV2)
}
