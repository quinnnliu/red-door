//
//  PullListV2ListItem.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/17/26.
//

import SwiftUI

struct PullListV2ListItem: View {
    let list: PullListV2

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(list.address.getStreetAddress() ?? "")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                (
                    Text("Install Date: ")
                        .foregroundColor(.red)
                    +
                    Text(list.installDate)
                        .foregroundColor(.secondary)
                )

                (
                    Text("Client ID: ")
                        .foregroundColor(.red)
                    +
                    Text(list.clientId)
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
//
//  PullListV2ListItem.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/17/26.
//

import SwiftUI

struct PullListV2ListItem: View {
    let list: PullListV2

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(list.address.getStreetAddress() ?? "")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                (
                    Text("Install Date: ")
                        .foregroundColor(.red)
                    +
                    Text(list.installDate)
                        .foregroundColor(.secondary)
                )

                (
                    Text("Client ID: ")
                        .foregroundColor(.red)
                    +
                    Text(list.clientId)
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
