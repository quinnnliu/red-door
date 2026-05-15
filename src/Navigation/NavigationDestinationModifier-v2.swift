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
            .navigationDestination(for: Model.self) { model in
                ModelDetailView(model: model)
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
            .navigationDestination(for: ItemWithModel.self) { itemWithModel in
                ItemDetailView(item: itemWithModel.item, model: itemWithModel.model)
            }
            .navigationDestination(for: ItemV2.self) { item in
                ItemDetailsViewV2(item: item)
            }
            .navigationDestination(for: RDList.self) { list in
                if list.listType == .pull_list && list.status == .planning {
                    PlanningPullListView(pullList: list)
                } else if list.listType == .pull_list && list.status == .staging {
                    StagingPullListView(pullList: list)
                } else if list.listType == .installed_list {
                    InstalledListDetailView(installedList: list)
                }
            }
            .navigationDestination(for: String.self) { string in
                Group {
                    if string == "might be useful" {}
                }
            }
    }
}

extension View {
    func rootNavigationDestinationsV2(path: Binding<NavigationPath>) -> some View {
        modifier(NavigationDestinationsModifierV2(path: path))
    }
}
