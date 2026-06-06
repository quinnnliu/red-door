//
//  NavigationCoordinator.swift
//  RedDoor
//
//  Created by Quinn Liu on 11/16/25.
//

// TODO: remove dead code from v2 structs

import SwiftUI

@Observable
class NavigationCoordinator {

    enum Tab: Int {
        case pullList = 0
        case installedList = 1
        case inventory = 2
        case itemInventory = 3
        case options = 4
        case pullListV2 = 5
    }

    var selectedTab: Tab = .pullList
    var inventoryPath: NavigationPath = NavigationPath()
    var pullListPath: NavigationPath = NavigationPath()
    var installedListPath: NavigationPath = NavigationPath()
    var itemInventoryPath: NavigationPath = NavigationPath()
    var optionsPath: NavigationPath = NavigationPath()
    var pullListV2Path: NavigationPath = NavigationPath()

    var selectedPath: NavigationPath {
        switch selectedTab {
        case .pullList:
            return pullListPath
        case .installedList:
            return installedListPath
        case .inventory:
            return inventoryPath
        case .itemInventory:
            return itemInventoryPath
        case .options:
            return optionsPath
        case .pullListV2:
            return pullListV2Path
        }
    }

    func setSelectedTab(to tab: Tab) {
        selectedTab = tab
    }

    func appendToSelectedPath(_ item: any Hashable) {
        switch selectedTab {
        case .pullList:
            pullListPath.append(item)
        case .installedList:
            installedListPath.append(item)
        case .inventory:
            inventoryPath.append(item)
        case .itemInventory:
            itemInventoryPath.append(item)
        case .options:
            optionsPath.append(item)
        case .pullListV2:
            pullListV2Path.append(item)
        }
    }
    
    func removeFromSelectedPath(_ k: Int? = nil) {
        switch selectedTab {
        case .pullList:
            pullListPath.removeLast(k ?? 1)
        case .installedList:
            installedListPath.removeLast(k ?? 1)
        case .inventory:
            inventoryPath.removeLast(k ?? 1)
        case .itemInventory:
            itemInventoryPath.removeLast(k ?? 1)
        case .options:
            optionsPath.removeLast(k ?? 1)
        case .pullListV2:
            pullListV2Path.removeLast(k ?? 1)
        }
    }

    func resetSelectedPath() {
        switch selectedTab {
        case .pullList:
            pullListPath = NavigationPath()
        case .installedList:
            installedListPath = NavigationPath()
        case .inventory:
            inventoryPath = NavigationPath()
        case .itemInventory:
            itemInventoryPath = NavigationPath()
        case .options:
            optionsPath = NavigationPath()
        case .pullListV2:
            pullListV2Path = NavigationPath()
        }
    }
}
