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
