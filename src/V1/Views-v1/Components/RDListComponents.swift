//
//  PullListComponents.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/10/25.
//

import SwiftUI

// MARK: RDList Top Bar

struct RDListTopBar<TrailingIcon: View>: View {
    @Binding var streetAddress: Address
    @ViewBuilder var trailingIcon: TrailingIcon

    private var status: InstallationStatus

    init(streetAddress: Binding<Address>, trailingIcon: TrailingIcon, status: InstallationStatus) {
        _streetAddress = streetAddress
        self.trailingIcon = trailingIcon
        self.status = status
    }

    var body: some View {
        TopAppBar(
            leadingView: { BackButton() },
            header: { 
                (
                    Text("\(status.rawValue.capitalized): ")
                        .foregroundColor(.red)
                        .bold()
                    +
                    Text(streetAddress.getStreetAddress() ?? "")
                )
            },
            trailingView: { trailingIcon }
        )
    }
}

// MARK: RDList Details

struct RDListDetails: View {
    let list: RDList

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                (
                    Text("Address: ")
                        .foregroundColor(.red)
                        .bold()
                    +
                    Text(list.address.formattedAddress)
                        .foregroundColor(.primary)
                )

                (
                    Text("Install Date: ")
                        .foregroundColor(.red)
                        .bold()
                    +
                    Text(list.installDate)
                        .foregroundColor(.primary)
                )

                (
                    Text("Uninstall Date: ")
                        .foregroundColor(.red)
                        .bold()
                    +
                    Text(list.uninstallDate)
                        .foregroundColor(.primary)    
                )

                (
                    Text("Client: ")
                        .foregroundColor(.red)
                        .bold()
                    +
                    Text(list.client)
                        .foregroundColor(.primary)
                )
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(.systemGray3), lineWidth: 4)
        )
    }
}

// MARK: RDList Document List Item

struct RDListDocumentListItem: View {
    let list: RDList

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(list.address.getStreetAddress() ?? "")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                (
                    Text(list.listType == .pull_list ? "Install Date: " : "Uninstall Date: ")
                        .foregroundColor(.red)
                    +
                    Text(list.listType == .pull_list ? list.installDate : list.uninstallDate)
                        .foregroundColor(.secondary)
                )

                (
                    Text("Client: ")
                        .foregroundColor(.red)
                    +
                    Text(list.client)
                        .foregroundColor(.secondary)
                )
            }
            .font(.caption)

            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray5))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(.systemGray3), lineWidth: 4)
        )
        .frame(maxWidth: .infinity) 
    }
}
