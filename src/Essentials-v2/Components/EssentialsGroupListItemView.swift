//
//  EssentialsGroupListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

import SwiftUI

enum EssentialsGroupListItemAction {
    case navigate(EssentialsGroup)
}

struct EssentialsGroupListItemView: View {
    let group: EssentialsGroup
    var emoji: String? = "⭐️"
    var action: ((Any?) -> Void)?
    var actionType: EssentialsGroupListItemAction

    init(group: EssentialsGroup, emoji: String? = "⭐️", action: ((Any?) -> Void)? = nil, actionType: EssentialsGroupListItemAction? = nil) {
        self.group = group
        self.emoji = emoji
        self.action = action
        self.actionType = actionType ?? .navigate(group)
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
        HStack(spacing: 12) {
            if let emoji = emoji {
                Text(emoji)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(group.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if group.location.status != .inStorage {
                        Text("• \(group.location.status.displayTitle)")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                HStack(spacing: 4) {
                    Text("\(group.itemIds.count) items")

                    if group.accessoriesId != nil {
                        Text("•")
                        Image(systemName: SFSymbols.booksVerticalFill)
                        Text("Accessories")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}
