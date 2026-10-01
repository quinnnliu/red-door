//
//  DocumentLocation.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/13/26.
//

import Foundation

struct DocumentLocation: Codable, Hashable {
    var status: LocationStatus
    var locationId: String

    enum CodingKeys: String, CodingKey {
        case status
        case locationId = "location_id"
    }
}

extension DocumentLocation {
    /// Draft placeholder for a create flow whose destination hasn't been picked
    /// yet. Screens must overwrite it before writing.
    static let unselectedStorage = DocumentLocation(status: .inStorage, locationId: "")
}

extension DocumentLocation {
    /// Firestore dot-notation key for filtering documents by `location.status`.
    static let statusFilterKey = "location.\(CodingKeys.status.stringValue)"
}

extension DocumentLocation {
      /// Firestore dot-notation fields for updating a nested `location` field in place.
      var firebaseUpdateFields: [String: Any] {
          [
              "location.\(CodingKeys.status.stringValue)": status.rawValue,
              "location.\(CodingKeys.locationId.stringValue)": locationId
          ]
      }
  }
