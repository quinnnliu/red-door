//
//  NavigationDestinationModifier.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/16/25.
//

import Foundation

import SwiftUI

struct NavigationDestinationsModifier: ViewModifier {
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
    func rootNavigationDestinations(path: Binding<NavigationPath>) -> some View {
        modifier(NavigationDestinationsModifier(path: path))
    }
}
