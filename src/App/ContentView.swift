//
//  ContentView.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/6/24.
//

import SwiftUI

struct ContentView: View {
    @State private var path = NavigationPath()
    @State private var coordinator: NavigationCoordinator = NavigationCoordinator()

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            Tab("Pull Lists (V2)", systemImage: "pencil.and.list.clipboard", value: NavigationCoordinator.Tab.pullListV2) {
                PullListDocumentListViewV2(path: $coordinator.pullListV2Path)
                    .tint(.blue)
                    .environment(coordinator)
            }
            
            Tab("Item Inventory (V2)", systemImage: "chair.lounge.fill", value: NavigationCoordinator.Tab.itemInventory) {
                ItemDocumentListViewV2(path: $coordinator.itemInventoryPath)
                    .tint(.blue)
                    .environment(coordinator)
            }
            
            Tab("Options (V2)", systemImage: "ellipsis.circle", value: NavigationCoordinator.Tab.optionsV2) {
                OptionsViewV2()
                    .tint(.blue)
                    .environment(coordinator)
            }
            
            Tab("Pull (v1)", systemImage: "pencil.and.list.clipboard", value: NavigationCoordinator.Tab.pullList) {
                PullListDocumentView(path: $coordinator.pullListPath)
                    .tint(.blue)
                    .environment(coordinator)
            }
            
            Tab("Inventory (V1)", systemImage: "chair.lounge.fill", value: NavigationCoordinator.Tab.inventory) {
                ModelInventoryView(path: $coordinator.inventoryPath)
                    .tint(.blue)
                    .environment(coordinator)
            }
            
            Tab("Installed (V1)", systemImage: "list.bullet.clipboard", value: NavigationCoordinator.Tab.installedList) {
                InstalledListDocumentView(path: $coordinator.installedListPath)
                    .tint(.blue)
                    .environment(coordinator)
            }

            Tab("Options", systemImage: "ellipsis.circle", value: NavigationCoordinator.Tab.options) {
                OptionsView()
                    .tint(.blue)
                    .environment(coordinator)
            }
        }.tint(.red)
    }
}

#Preview {
    ContentView()
}
