//
//  NullEncodable.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/13/26.
//

/// Property wrapper that encodes optional values as explicit `null` in Firestore
/// instead of omitting the field. This allows Firestore queries like
/// `.whereField("field", isEqualTo: NSNull())` to match documents where the field
/// is unset, which otherwise requires the field to exist with a null value.
@propertyWrapper
struct NullEncodable<T: Codable>: Codable {
    var wrappedValue: T?

    init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let value = wrappedValue {
            try container.encode(value)
        } else {
            try container.encodeNil()
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try? container.decode(T.self)
    }
}

extension NullEncodable: Equatable where T: Equatable {}
extension NullEncodable: Hashable where T: Hashable {}

/// When the field is absent from a Firestore document (legacy data), decode as nil.
extension KeyedDecodingContainer {
    func decode<T: Decodable>(_ type: NullEncodable<T>.Type, forKey key: Key) throws -> NullEncodable<T> {
        try decodeIfPresent(type, forKey: key) ?? NullEncodable(wrappedValue: nil)
    }
}
