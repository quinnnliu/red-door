//
//  DocumentLocation.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/13/26.
//

import Firebase
import Foundation

struct DocumentLocation: Codable, Hashable {
    var status: LocationStatus
    var locationId: String
    var locationName: String?
    var assignedAt: Date?

    init(status: LocationStatus, locationId: String, locationName: String? = nil, assignedAt: Date? = .now) {
        self.status = status
        self.locationId = locationId
        self.locationName = locationName
        self.assignedAt = assignedAt
    }

    enum CodingKeys: String, CodingKey {
        case status
        case locationId = "location_id"
        case locationName = "location_name"
        case assignedAt = "assigned_at"
    }
}

extension DocumentLocation {
    /// A location in the given storage location, stamped now.
    init(storageLocation: StorageLocation) {
        self.init(status: .inStorage, locationId: storageLocation.id, locationName: storageLocation.displayName)
    }
}

extension DocumentLocation {
    /// Draft placeholder for a create flow whose destination hasn't been picked
    /// yet. Screens must overwrite it before writing.
    static let unselectedStorage = DocumentLocation(status: .inStorage, locationId: "", assignedAt: nil)
}

extension DocumentLocation {
    /// Only pull lists and installed lists with a real id have a screen to
    /// navigate to. Storage locations don't.
    var isNavigable: Bool {
        status != .inStorage && !locationId.isEmpty
    }
}

extension DocumentLocation {
    /// Firestore dot-notation key for filtering documents by `location.status`.
    static let statusFilterKey = "location.\(CodingKeys.status.stringValue)"
}

extension DocumentLocation {
    /// Firestore dot-notation fields for updating a nested `location` field in place.
    /// Nil optionals are deleted so a stale name or timestamp can't outlive a move.
    var firebaseUpdateFields: [String: Any] {
        [
            "location.\(CodingKeys.status.stringValue)": status.rawValue,
            "location.\(CodingKeys.locationId.stringValue)": locationId,
            "location.\(CodingKeys.locationName.stringValue)": locationName ?? FieldValue.delete(),
            "location.\(CodingKeys.assignedAt.stringValue)": assignedAt.map { Timestamp(date: $0) } ?? FieldValue.delete()
        ]
    }

    func toFirebaseMap() throws -> [String: Any] {
        try Firestore.Encoder().encode(self)
    }
}
