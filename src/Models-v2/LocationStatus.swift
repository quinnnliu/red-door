//
//  LocationStatus.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import SwiftUI

enum LocationStatus: String, Codable, Filterable {
    case inStorage = "in_storage"
    case inPullList = "in_pull_list"
    case inInstalledList = "in_installed_list"

    var title: String { displayTitle }
    var icon: String? {
        switch self {
        case .inInstalledList: SFSymbols.houseFill
        case .inPullList: SFSymbols.pencilAndListClipboard
        case .inStorage: SFSymbols.shippingbox
        }
    }
    var color: Color? { nil }

    var displayTitle: String {
        switch self {
        case .inPullList:
            "In Pull List"
        case .inStorage:
            "In Storage"
        case .inInstalledList:
            "Installed"
        }
    }
}
