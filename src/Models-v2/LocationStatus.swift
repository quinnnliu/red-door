//
//  LocationStatus.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

enum LocationStatus: String, Codable {
    case inPullList = "in_pull_list"
    case inStorage = "in_storage"
    case inInstalledList = "in_installed_list"

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
