//
//  RDListDocument.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/30/26.
//

protocol RDListDocument: RDDocument {
    static var listType: RDListType { get }

    /// False once the list is a historical record. An uninstalled list still
    /// renders its rooms, but every write to the list or its rooms is rejected.
    var acceptsChanges: Bool { get }
}

extension RDListDocument {
    var acceptsChanges: Bool { true }

    static var itemLocationStatus: LocationStatus { listType.itemLocationStatus }
}

enum RDListType: String, Hashable, Codable {
    case pullList
    case installedList

    var itemLocationStatus: LocationStatus {
        switch self {
        case .pullList: .inPullList
        case .installedList: .inInstalledList
        }
    }
}
