//
//  PullListListItemV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/17/26.
//

import SwiftUI

enum PullListListItemAction {
    case documentList(list: PullListV2)
    case assignEssentialsToList(list: PullListV2)
}

struct PullListListItemV2: View {
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
        HStack(alignment: .center, spacing: Constants.Padding(1)) {
            LeadingContent
            
            CenterContent

            Spacer(minLength: 0)

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

private extension PullListListItemV2 {
    var LeadingContent: some View {
        HStack(spacing: Constants.Padding(1)) {
            PrimaryImageView(image: list.image, size: Constants.Image.listItemLarge, isExpandable: false)
        }
    }
    
    var CenterContent: some View {
        VStack(alignment: .leading, spacing: Constants.Padding(0.5)) {
            Text(list.displayName)
                .font(.headline)

            VStack(alignment: .leading, spacing: Constants.Padding(0.25)) {
                (
                    Text("Install Date: ")
                        .foregroundColor(.red)
                    +
                    Text(list.installDate.displayDate)
                        .foregroundColor(.secondary)
                )

                (
                    Text("Client: ")
                        .foregroundColor(.red)
                    +
                    Text(list.clientId)
                        .foregroundColor(.secondary)
                )
            }
            .font(.caption)
        }
    }
}
