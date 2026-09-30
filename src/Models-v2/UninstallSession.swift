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
struct UninstallSession: ListSessionDocument {
    static let collectionName: String = "uninstall_sessions"
    static let orderByField: String = UninstallSession.CodingKeys.id.stringValue
    static let searchField: String = UninstallSession.CodingKeys.id.stringValue

    var id: String
    var baseName: String { id }

    /// Fencing token. Bumped on every takeover. A client holding a lower
    /// generation than this has been displaced and is read-only.
    /// Written from the start; enforced in the UI later.
    var lockGeneration: Int

    var copyPullListId: String?

    var copyListAddress: Address?

    var existingPullListId: String?

    var itemDestinations: [String: UninstallDestination]

    var essentialsDestination: UninstallDestination?

    @DecodableDefault.False var uninstalled: Bool
    
    var uninstalledDate: String?
    
    var essentialsGroupId: String?
    
    @DecodableDefault.EmptyList var essentialsItemIds: [String]

    init(
        id: String,
        lockGeneration: Int = 1,
        copyPullListId: String? = nil,
        copyListAddress: Address? = nil,
        existingPullListId: String? = nil,
        itemDestinations: [String: UninstallDestination] = [:],
        essentialsDestination: UninstallDestination? = nil,
        uninstalled: Bool = false,
        uninstalledDate: String? = nil,
        essentialsGroupId: String? = nil,
        essentialsItemIds: [String] = []
    ) {
        self.id = id
        self.lockGeneration = lockGeneration
        self.copyPullListId = copyPullListId
        self.copyListAddress = copyListAddress
        self.existingPullListId = existingPullListId
        self.itemDestinations = itemDestinations
        self.essentialsDestination = essentialsDestination
        self.uninstalled = uninstalled
        self.uninstalledDate = uninstalledDate
        self.essentialsGroupId = essentialsGroupId
        self.essentialsItemIds = essentialsItemIds
    }

    var isComplete: Bool { uninstalled }

    static func newSession(id: String) -> UninstallSession {
        UninstallSession(id: id, lockGeneration: 1)
    }
    static var lockGenerationField: String { CodingKeys.lockGeneration.stringValue }
    static var itemDestinationsField: String { CodingKeys.itemDestinations.stringValue }

    enum CodingKeys: String, CodingKey {
        case id
        case lockGeneration = "lock_generation"
        case copyPullListId = "copy_pull_list_id"
        case copyListAddress = "copy_list_address"
        case existingPullListId = "existing_pull_list_id"
        case itemDestinations = "item_destinations"
        case essentialsDestination = "essentials_destination"
        case uninstalled
        case uninstalledDate = "uninstalled_date"
        case essentialsGroupId = "essentials_group_id"
        case essentialsItemIds = "essentials_item_ids"
    }
}

// MARK: - UninstallDestination

struct UninstallDestination: Codable, Hashable {
    var type: UninstallDestinationType
    var locationId: String

    enum CodingKeys: String, CodingKey {
        case type
        case locationId = "location_id"
    }
}

enum UninstallDestinationType: String, Codable {
    case storage
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
        case .storage:
            DocumentLocation(status: .inStorage, locationId: locationId)
        case .copy, .existingList:
            DocumentLocation(status: .inPullList, locationId: locationId)
        }
    }
}
