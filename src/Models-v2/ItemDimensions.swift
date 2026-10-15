//
//  ItemDimensions.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/30/26.
//

struct ItemDimensions: Codable, Hashable {
    var length: String
    var width: String
    var height: String
    var depth: String?
    var unit: UnitType

    enum UnitType: String, Codable, CaseIterable {
        case imperial, metric
    }

    enum CodingKeys: String, CodingKey {
        case length
        case width
        case height
        case depth
        case unit
    }
}

extension ItemDimensions {
    /// "L × W × H × D in", skipping any empty measurement. Nil when all are empty.
    var summary: String? {
        let parts = [length, width, height, depth ?? ""].filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }

        let unitSymbol = unit == .imperial ? "in" : "cm"
        return parts.joined(separator: " × ") + " " + unitSymbol
    }
}
