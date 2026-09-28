//
//  UninstallSession.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import Foundation

/// Transient plan for uninstalling an installed list. Assignments accumulate
/// here and are applied all at once on commit, so nothing moves until the
/// whole plan has been reviewed.
///
/// The document ID is always the `InstalledListV2.id`, which makes "is an
/// uninstall in progress?" a single `get(id:)` and gives the create path a
/// deterministic target.
struct UninstallSession: RDDocument {
    static let collectionName: String = "uninstall_sessions"
    static let orderByField: String = UninstallSession.CodingKeys.id.stringValue
    static let searchField: String = UninstallSession.CodingKeys.id.stringValue

    var id: String
    var baseName: String { id }

    /// Fencing token. Bumped on every takeover. A client holding a lower
    /// generation than this has been displaced and is read-only.
    /// Written from the start; enforced in the UI later.
    var lockGeneration: Int

    /// Pre-generated ID for the copy pull list. The `PullListV2` document is not
    /// created until commit, so an abandoned session leaves no orphaned list.
    var copyPullListId: String?

    /// The single existing pull list targeted by this session, if any.
    var existingPullListId: String?

    /// Keyed by item ID.
    var itemDestinations: [String: UninstallDestination]

    /// The essentials group moves as one unit: this single destination covers the group document.
    var essentialsDestination: UninstallDestination?

    init(
        id: String,
        lockGeneration: Int = 1,
        copyPullListId: String? = nil,
        existingPullListId: String? = nil,
        itemDestinations: [String: UninstallDestination] = [:],
        essentialsDestination: UninstallDestination? = nil
    ) {
        self.id = id
        self.lockGeneration = lockGeneration
        self.copyPullListId = copyPullListId
        self.existingPullListId = existingPullListId
        self.itemDestinations = itemDestinations
        self.essentialsDestination = essentialsDestination
    }

    enum CodingKeys: String, CodingKey {
        case id
        case lockGeneration = "lock_generation"
        case copyPullListId = "copy_pull_list_id"
        case existingPullListId = "existing_pull_list_id"
        case itemDestinations = "item_destinations"
        case essentialsDestination = "essentials_destination"
    }
}

// MARK: - UninstallDestination

struct UninstallDestination: Codable, Hashable {
    var type: UninstallDestinationType
    /// warehouseId | copyPullListId | existingPullListId
    var locationId: String

    enum CodingKeys: String, CodingKey {
        case type
        case locationId = "location_id"
    }
}

enum UninstallDestinationType: String, Codable {
    case warehouse
    case copy
    case existingList = "existing_list"
}

extension UninstallSession {
    func itemIds(for type: UninstallDestinationType) -> [String] {
        itemDestinations.filter { $0.value.type == type }.map(\.key)
    }
    var targetsCopy: Bool {
        targets(.copy)
    }
    var targetsExistingList: Bool {
        targets(.existingList)
    }
    private func targets(_ type: UninstallDestinationType) -> Bool {
        itemDestinations.values.contains { $0.type == type }
            || essentialsDestination?.type == type
    }
}

extension UninstallDestination {
    /// Bridge to the shared location model so commits reuse
    /// `DocumentLocation.firebaseUpdateFields` dot-notation.
    var documentLocation: DocumentLocation {
        switch type {
        case .warehouse:
            DocumentLocation(status: .inStorage, locationId: locationId)
        case .copy, .existingList:
            DocumentLocation(status: .inPullList, locationId: locationId)
        }
    }
}
