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
                    ItemDetailsViewV2(item: item)
                case .pullListDetailView(let list):
                    PullListV2DetailsView(list: list)
                case .roomDetailView(let room, let list):
                    Text("placholder room detail view for room \(room.displayName) in list \(list.id)")
                case .pullListItemDetailView(let item, let list):
                    Text("placeholder itemdetailview for item \(item.id) for pull list \(list.id)")
                }
            }
    }
}

extension View {
    func rootNavigationDestinationsV2(path: Binding<NavigationPath>) -> some View {
        modifier(NavigationDestinationsModifierV2(path: path))
    }
}
