//
//  DayGranular.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/29/26.
//

import Foundation

/// Property wrapper that pins a `Date` to the start of its calendar day.
@propertyWrapper
struct DayGranular: Codable, Hashable {
    private var storage: Date

    var wrappedValue: Date {
        get { storage }
        set { storage = Self.normalize(newValue) }
    }

    init(wrappedValue: Date) {
        storage = Self.normalize(wrappedValue)
    }

    init(from decoder: Decoder) throws {
        storage = Self.normalize(try Date(from: decoder))
    }

    func encode(to encoder: Encoder) throws {
        try storage.encode(to: encoder)
    }

    /// Uses the device calendar, so two devices in different time zones normalize
    /// the same calendar day to different instants.
    private static func normalize(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
}
