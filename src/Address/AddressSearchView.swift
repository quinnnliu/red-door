//
//  AddressSearchView.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/21/25.
//

import MapKit
import SwiftUI

struct AddressSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAddress: Address
    @Binding var addressId: String

    @State private var unit: String = ""

    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var cameraPosition: MapCameraPosition = .automatic

    @State private var selectedItem: MKMapItem?

    // MARK: Init
    
    init(_ selectedAddress: Binding<Address>, addressId: Binding<String>) {
        _selectedAddress = selectedAddress
        _addressId = addressId
        unit = ""
        searchText = ""
        searchResults = []
        selectedItem = nil
        cameraPosition = .automatic
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 12) {
            TextField("Search address", text: $searchText)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray5), lineWidth: 2)
                )
                .onSubmit {
                    searchAddress(searchText)
                }

            Map(position: $cameraPosition, selection: $selectedItem) {
                ForEach(searchResults, id: \.self) { item in
                    Marker(item.name ?? "Location", coordinate: item.placemark.coordinate)
                        .tag(item)
                }
            }
            .cornerRadius(8)
            .layoutPriority(searchResults.isEmpty ? 1 : 0)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(searchResults, id: \.self) { result in
                        SearchListItem(result)
                    }
                }
                .padding(2)
            }

            if selectedItem != nil {
                Footer()
            }
        }
    }

    // MARK: Footer

    @ViewBuilder
    private func Footer() -> some View {
        HStack(spacing: 0) {
            if let item: MKMapItem = selectedItem {
                TextField("Specify Unit", text: $unit)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray5), lineWidth: 2)
                    )

                Spacer()

                RDButton(variant: .default, label: "Use This Address", fullWidth: true) {
                    if let address = convertToAddress(item) {
                        selectedAddress = address
                        addressId = address.id
                    }
                    dismiss()
                }
            }
        }
    }

    // MARK: Search List Item

    @ViewBuilder
    private func SearchListItem(_ mapItem: MKMapItem) -> some View {
        let isSelected = mapItem == selectedItem
        Button {
            selectedItem = mapItem
            cameraPosition = .region(MKCoordinateRegion(
                center: mapItem.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(mapItem.name ?? "Unknown Name")
                    .foregroundStyle(.primary)
                Text(formatAddress(mapItem) ?? "Unknown Address")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.6) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue.opacity(0.6) : Color(.systemGray5), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Search Address Function

    private func searchAddress(_ searchText: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else {
                print("Search error: \(error?.localizedDescription ?? "Unknown")")
                searchResults = []
                return
            }
            searchResults = response.mapItems
            selectedItem = nil
            if let first = response.mapItems.first {
                cameraPosition = .region(MKCoordinateRegion(
                    center: first.placemark.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
    }

    // MARK: - Placemark Implementation

    private func formatAddress(_ mapItem: MKMapItem) -> String? {
        if #available(iOS 27, *) {
            if let address = mapItem.address {
                return address.fullAddress
            } else {
                return nil
            }
        } else {
            let placemark = mapItem.placemark

            let street = placemark.thoroughfare ?? ""
            let city = placemark.locality ?? ""
            let state = placemark.administrativeArea ?? ""
            let zipcode = placemark.postalCode ?? ""
            let country = placemark.country ?? ""
            return Address.formattedAddress(street: street, city: city, state: state, zipcode: zipcode, country: country, unit: unit)
        }
    }

    // MARK: Convert to Address Function

    private func convertToAddress(_ mapItem: MKMapItem) -> Address? {
        if #available(iOS 27, *) {
            if let address = mapItem.address {
                return Address(address: address, unit: unit)
            } else {
                return nil
            }
        } else {
            let placemark = mapItem.placemark
            return Address(placemark: placemark, unit: unit)
        }
    }
}
