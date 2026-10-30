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

enum EssentialsGroupListItemStyle {
    case list
    case inventory
}

struct EssentialsGroupListItemView: View {
    let group: EssentialsGroup
    var emoji: String? = "⭐️"
    var action: ((Any?) -> Void)?
    var actionType: EssentialsGroupListItemAction
    let style: EssentialsGroupListItemStyle

    init(
        group: EssentialsGroup,
        emoji: String? = "⭐️",
        action: ((Any?) -> Void)? = nil,
        actionType: EssentialsGroupListItemAction? = nil,
        style: EssentialsGroupListItemStyle = .inventory
    ) {
        self.group = group
        self.emoji = emoji
        self.action = action
        self.actionType = actionType ?? .navigate(group)
        self.style = style
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
            LeadingContent

            Spacer(minLength: .zero)
            
            TrailingContent
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(Constants.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                .stroke(Color(.systemGray5), lineWidth: 2)
        )
    }
    
    // MARK: LeadingContent
    @ViewBuilder
    private var LeadingContent: some View {
        HStack(spacing: 4) {
            if let emoji = emoji {
                Text(emoji)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(group.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 2) {
                    Text("\(group.itemIds.count) items")
                    
                    if group.accessoriesId != nil {
                        Text("•")
                        Image(systemName: SFSymbols.booksVerticalFill)
                        Text("Accessories")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.primary)
            }
        }
    }
    
    // MARK: TrailingContent
    @ViewBuilder
    private var TrailingContent: some View {
        switch style {
        case .list:
            EmptyView()
        case .inventory:
            LocationStatusCTA(location: group.location)
        }
    }
}
