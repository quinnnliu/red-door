//
//  AddressEntryView.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/22/25.
//

import SwiftUI

struct AddressEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAddress: Address
    @Binding var addressId: String

    @State private var street: String
    @State private var town: String
    @State private var state: String
    @State private var zipcode: String
    @State private var country: String
    @State private var unit: String

    init(_ selectedAddress: Binding<Address>, addressId: Binding<String>) {
        _selectedAddress = selectedAddress
        _addressId = addressId
        let address = selectedAddress.wrappedValue
        if address.isInitialized() {
            let components = address.formattedAddress.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            street = components.indices.contains(0) ? components[0] : ""
            town = components.indices.contains(1) ? components[1] : ""
            state = components.indices.contains(2) && !components[2].isEmpty ? components[2] : "MA"
            zipcode = components.indices.contains(3) ? components[3] : ""
            country = components.indices.contains(4) ? components[4] : "USA"
            unit = components.indices.contains(5) ? components[5] : ""
        } else {
            street = ""
            town = ""
            state = "MA"
            zipcode = ""
            country = "USA"
            unit = ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                FormField(label: "Street Address", text: $street)
                FormField(label: "Unit (Optional)", text: $unit)
            }
            HStack(spacing: 8) {
                FormField(label: "Town", text: $town)
                FormField(label: "Zipcode", text: $zipcode)
            }

            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("State")
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                    Picker("State", selection: $state) {
                        ForEach(states, id: \.self) { state in
                            Text(state).tag(state)
                        }
                    }
                    .pickerStyle(.menu)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }

                FormField(label: "Country", text: $country)
            }

            Spacer()


            RDButton(variant: .default, label: "Save Address", fullWidth: true) {
                updateSelectedAddress()
                dismiss()
            }
        }
    }
    
    @ViewBuilder
    private func FormField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
            TextField("", text: text)
                .padding(6)
                .background(Color(.systemGray5))
                .cornerRadius(8)
        }
    }

    private func updateSelectedAddress() {
        selectedAddress = Address(street: street, city: town, state: state, zipcode: zipcode, country: country, unit: unit)
        addressId = selectedAddress.id
    }

    let states: [String] = [
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
        "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
        "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
        "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
        "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY",
    ]
}
