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
        case itemInventory = 0
        case pullListV2 = 1
        case installedListV2 = 2
        case optionsV2 = 3
        case pullList = 4
        case installedList = 5
        case inventory = 6
        case options = 7
    }

    var selectedTab: Tab = .itemInventory
    var inventoryPath: NavigationPath = NavigationPath()
    var pullListPath: NavigationPath = NavigationPath()
    var installedListPath: NavigationPath = NavigationPath()
    var itemInventoryPath: NavigationPath = NavigationPath()
    var optionsPath: NavigationPath = NavigationPath()
    var optionsV2Path: NavigationPath = NavigationPath()
    var pullListV2Path: NavigationPath = NavigationPath()
    var installedListV2Path: NavigationPath = NavigationPath()

    var selectedPath: NavigationPath {
        switch selectedTab {
        case .itemInventory:
            return itemInventoryPath
        case .pullListV2:
            return pullListV2Path
        case .optionsV2:
            return optionsV2Path
        case .installedListV2:
            return installedListV2Path
            
        // MARK: below are dead tabs
        case .pullList:
            return pullListPath
        case .installedList:
            return installedListPath
        case .inventory:
            return inventoryPath
        case .options:
            return optionsPath
        }
    }

    func setSelectedTab(to tab: Tab) {
        selectedTab = tab
    }

    func appendToSelectedPath(_ item: any Hashable) {
        switch selectedTab {
        case .itemInventory:
            itemInventoryPath.append(item)
        case .pullListV2:
            pullListV2Path.append(item)
        case .optionsV2:
            optionsV2Path.append(item)
        case .installedListV2:
            installedListV2Path.append(item)
            
        // MARK: below are dead tabs
        case .pullList:
            pullListPath.append(item)
        case .installedList:
            installedListPath.append(item)
        case .inventory:
            inventoryPath.append(item)
        case .options:
            optionsPath.append(item)
        }
    }
    
    func removeFromSelectedPath(_ k: Int? = nil) {
        switch selectedTab {
        case .itemInventory:
            itemInventoryPath.removeLast(k ?? 1)
        case .pullListV2:
            pullListV2Path.removeLast(k ?? 1)
        case .optionsV2:
            optionsV2Path.removeLast(k ?? 1)
        case .installedListV2:
            installedListV2Path.removeLast(k ?? 1)
            
        // MARK: below are dead tabs
        case .pullList:
            pullListPath.removeLast(k ?? 1)
        case .installedList:
            installedListPath.removeLast(k ?? 1)
        case .inventory:
            inventoryPath.removeLast(k ?? 1)
        case .options:
            optionsPath.removeLast(k ?? 1)
        
        }
    }

    func resetSelectedPath() {
        switch selectedTab {
        case .itemInventory:
            itemInventoryPath = NavigationPath()
        case .pullListV2:
            pullListV2Path = NavigationPath()
        case .optionsV2:
            optionsV2Path = NavigationPath()
        case .installedListV2:
            installedListV2Path = NavigationPath()
            
        // MARK: below are dead tabs
        case .pullList:
            pullListPath = NavigationPath()
        case .installedList:
            installedListPath = NavigationPath()
        case .inventory:
            inventoryPath = NavigationPath()
        case .options:
            optionsPath = NavigationPath()
        }
    }
}
