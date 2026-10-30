//
//  AccessoriesListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

import SwiftUI

enum AccessoriesListItemAction: Equatable {
    case navigate(Accessories)
    case select(Accessories)
}

enum AccessoriesListItemStyle: Equatable {
    case navigate(Accessories)
    case essentialsGroup
    case list
}

struct AccessoriesListItemView: View {
    let accessories: Accessories
    var action: ((Any?) -> Void)?
    var actionType: AccessoriesListItemAction
    let style: AccessoriesListItemStyle
    var onRemove: (() -> Void)?

    init(
        _ accessories: Accessories,
        action: ((Any?) -> Void)? = nil,
        actionType: AccessoriesListItemAction? = nil,
        style: AccessoriesListItemStyle = .essentialsGroup,
        onRemove: (() -> Void)? = nil
    ) {
        self.accessories = accessories
        self.action = action
        self.actionType = actionType ?? .navigate(accessories)
        self.style = style
        self.onRemove = onRemove
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
        HStack(spacing: 8) {
            PrimaryImageView(image: accessories.primaryImage, size: Constants.Image.listItemDefault, isExpandable: false)

            Text(accessories.displayName)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }

    // MARK: TrailingContent
    @ViewBuilder
    private var TrailingContent: some View {
        switch style {
        case .navigate(let accessories):
            LocationStatusCTA(location: accessories.location)
        case .essentialsGroup:
            HStack(spacing: 4) {
                LocationStatusCTA(location: accessories.location)
                
                if let onRemove, style == .essentialsGroup {
                    Button(action: onRemove) {
                        Image(systemName: SFSymbols.xmark)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        case .list:
            EmptyView()
        }
        
    }
}
