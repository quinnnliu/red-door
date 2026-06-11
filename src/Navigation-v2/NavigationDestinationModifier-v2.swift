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
                case .pulllistRoomDetailView(let items, let room):
                    PullListRoomDetailsView(items: items, room: room)
                case .pullListItemDetailView(let item, let room):
                    PullListItemDetailView(item: item, room: room)
                case .addItemToRoomDetailView(let item, let room):
                    AddItemToRoomDetailView(item: item, room: room)
                case .installedListDetailView(let list):
                    Text(list.displayName)
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
