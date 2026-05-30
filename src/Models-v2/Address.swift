//
//  Address.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/6/25.
//

import CoreLocation
import Foundation
import MapKit

struct Address: Codable, Hashable {
    var id: String // address string that's lowercased, trimmed, not punctuation
    var formattedAddress: String
    var isWarehouse: Bool?
//    var coordinates: GeoPoint?

    // MARK: Init

    init(
        street: String = "",
        city: String = "",
        state: String = "",
        zipcode: String = "",
        country: String = "",
        unit: String? = nil,
        isWarehouse: Bool? = nil,
        //        coordinates: GeoPoint? = nil
    ) {
        // ID: concatenated, lowercased, trimmed, no punctuation or spaces
        id = Address.normalize([street, city, state, zipcode, country].joined())

        formattedAddress = Address.formattedAddress(street: street, city: city, state: state, zipcode: zipcode, country: country, unit: unit)

        self.isWarehouse = isWarehouse
    }

    @available(iOS 26.0, *)
    init(address: MKAddress, unit: String? = nil, isWarehouse: Bool? = nil) {
        id = Address.normalize(address.fullAddress)
        formattedAddress = address.fullAddress
        if let unit = unit {
            formattedAddress += ", " + unit
        }
        self.isWarehouse = isWarehouse
    }

    init(placemark: MKPlacemark, unit: String? = nil, isWarehouse: Bool? = nil) {
        let street = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        let city = placemark.locality ?? ""
        let state = placemark.administrativeArea ?? ""
        let zipcode = placemark.postalCode ?? ""
        let country = placemark.country ?? ""

        id = Address.normalize([street, city, state, zipcode, country].joined())

        formattedAddress = Address.formattedAddress(street: street, city: city, state: state, zipcode: zipcode, country: country, unit: unit)
        self.isWarehouse = isWarehouse
    }

    // MARK: isInitialized

    func isInitialized() -> Bool {
        !id.isEmpty && !formattedAddress.isEmpty
    }

    // MARK: Formatted Address
    static func formattedAddress(street: String, city: String, state: String, zipcode: String, country: String, unit: String? = nil) -> String {
        return [
            street,
            city,
            state,
            zipcode,
            country,
            unit,
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }

    // MARK: Normalize

    static func normalize(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercase = trimmed.lowercased()
        let noPunctuation = lowercase.components(separatedBy: CharacterSet.punctuationCharacters).joined()
        let noSpaces = noPunctuation.replacingOccurrences(of: " ", with: "")
        return noSpaces
    }

    // MARK: Get Street Address

    func getStreetAddress() -> String? {
        return formattedAddress.split(separator: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Get 

    func getCityStateZipcode() -> String? {
        return formattedAddress.split(separator: ", ").dropFirst().dropLast().joined(separator: ", ")
    }
}
