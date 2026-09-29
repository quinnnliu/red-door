//
//  InstallSession.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation

/// Transient plan for installing a pull list. Assignments accumulate here and
/// are applied all at once on commit, so nothing moves until the owner installs.
///
/// Unlike the uninstall session, an absent key is not "undecided" — installing
/// is the default, so the map holds only the items diverted to storage. That
/// keeps writes small, avoids racing to seed a session before rooms have
/// loaded, and gives items added mid-session the right default.
struct InstallSession: ListSessionDocument {
    static let collectionName: String = "install_sessions"
    static let orderByField: String = InstallSession.CodingKeys.id.stringValue
    static let searchField: String = InstallSession.CodingKeys.id.stringValue

    var id: String
    var baseName: String { id }

    var lockGeneration: Int

    var itemDestinations: [String: DocumentLocation]

    /// The install commit still deletes its session, so there is no terminal
    /// state to report.
    var isComplete: Bool { false }

    init(
        id: String,
        lockGeneration: Int = 1,
        itemDestinations: [String: DocumentLocation] = [:]
    ) {
        self.id = id
        self.lockGeneration = lockGeneration
        self.itemDestinations = itemDestinations
    }

    static func newSession(id: String) -> InstallSession {
        InstallSession(id: id, lockGeneration: 1)
    }
    static var lockGenerationField: String { CodingKeys.lockGeneration.stringValue }
    static var itemDestinationsField: String { CodingKeys.itemDestinations.stringValue }

    enum CodingKeys: String, CodingKey {
        case id
        case lockGeneration = "lock_generation"
        case itemDestinations = "item_destinations"
    }
}

extension InstallSession {
    /// The destination an item will actually get on commit. Anything absent
    /// from the map installs into the list.
    func destination(for itemId: String, installedListId: String) -> DocumentLocation {
        itemDestinations[itemId]
            ?? DocumentLocation(status: .inInstalledList, locationId: installedListId)
    }
}
