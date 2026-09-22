//
//  PullListV2ListItem.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/17/26.
//

import SwiftUI

enum PullListListItemAction {
    case documentList(list: PullListV2)
    case assignEssentialsToList(list: PullListV2)
}

struct PullListV2ListItem: View {
    let list: PullListV2
    var action: ((Any?) -> Void)?
    var actionType: PullListListItemAction

    init(list: PullListV2, action: ((Any?) -> Void)? = nil, actionType: PullListListItemAction? = nil) {
        self.list = list
        self.action = action
        self.actionType = actionType ?? .documentList(list: list)
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
            PrimaryImageView(image: list.image, size: Constants.Image.listItemLarge, isExpandable: false)
            
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
