//
//  InstalledListV2ListItem.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/10/26.
//

import SwiftUI

enum InstalledListListItemAction {
    case navigate(InstalledListV2)
}

struct InstalledListV2ListItem: View {
    let list: InstalledListV2
    var action: ((Any?) -> Void)?
    var actionType: InstalledListListItemAction

    init(list: InstalledListV2, action: ((Any?) -> Void)? = nil, actionType: InstalledListListItemAction? = nil) {
        self.list = list
        self.action = action
        self.actionType = actionType ?? .navigate(list)
    }

    var body: some View {
        Group {
            if let action {
                Button {
                    action(actionType)
                } label: {
                    cellContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cellContent
            }
        }
    }

    private var cellContent: some View {
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
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray3), lineWidth: 4)
        )
        .frame(maxWidth: .infinity)
    }
}
