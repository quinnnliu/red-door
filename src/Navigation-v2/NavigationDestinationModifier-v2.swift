//
//  NavigationDestinationModifier-v2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import Foundation
import SwiftUI

struct NavigationDestinationsModifierV2: ViewModifier {
    @Binding var path: NavigationPath
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .itemDetailView(let item):
                    ItemDetailViewV2(item: item)
                case .pullListDetailView(let list):
                    PullListV2DetailsView(list: list)
                case .roomDetailView(let items, let room):
                    RoomDetailsView(items: items, room: room)
                case .pullListItemDetailView(let item, let room, let rooms, let list):
                    PullListItemDetailView(item: item, room: room, rooms: rooms, list: list)
                case .addItemToRoomDetailView(let item, let room):
                    AddItemToRoomDetailView(item: item, room: room)
                default:
                    Text("UNHANDLED NAVIGATION DESTINATION")
                }
            }
    }
}

extension View {
    func rootNavigationDestinationsV2(path: Binding<NavigationPath>) -> some View {
        modifier(NavigationDestinationsModifierV2(path: path))
    }
}
