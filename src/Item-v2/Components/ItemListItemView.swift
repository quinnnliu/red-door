//
//  ItemListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import SwiftUI

enum ItemListItemStyle {
    case inventoryList
    case addToDocument
    case essentialsGroup
    case display
    case installation(room: RoomV2)
    case listRoom
}

enum ItemListItemAction {
    case navigate(ItemV2)
    case copyItem(ItemV2)
    case removeItem(ItemV2)
    case multiSelectSelection(ItemV2)
    case multiSelectDeselection(ItemV2)
}

struct ItemListItemView: View {
    private let item: ItemV2
    private var style: ItemListItemStyle
    private let essentialsEmoji: String
    private let isSelected: Bool
    private var action: ((Any) -> Void)? = nil

    init(
        item: ItemV2,
        style: ItemListItemStyle = .inventoryList,
        essentialsEmoji: String = "⭐️",
        isSelected: Bool = false,
        action: ((Any) -> Void)? = nil
    ) {
        self.item = item
        self.style = style
        self.essentialsEmoji = essentialsEmoji
        self.isSelected = isSelected
        self.action = action
    }

    // MARK: Body
    var body: some View {
        Group {
            switch style {
            case .inventoryList, .addToDocument, .display, .listRoom:
                Button {
                    if let action = action {
                        action(ItemListItemAction.navigate(item))
                    }
                } label: {
                    ListItemContent
                }
                .buttonStyle(PlainButtonStyle())
            default:
                ListItemContent
            }
        }
    }

    private var ListItemContent: some View {
        HStack(spacing: .zero) {
            LeadingContent
            
            BodyContent

            Spacer(minLength: 4)

            TrailingContent
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(Constants.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: Constants.CornerRadius.large)
                .stroke(item.attention ? .orange : Color(.systemGray5), lineWidth: 2)
        )
    }
}

// MARK: - BodyContent
private extension ItemListItemView {
    var BodyContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(item.displayName)
                    .font(.callout)
                    .bold()
                    .foregroundStyle(.primary)
                
                StatusCTA
            }

            HStack(spacing: 4) {
                Image(systemName: item.type.icon ?? SFSymbols.ellipsis)
                Text(item.type.title)
                Text("•")
                Text(item.material.title)
                if let color = item.color.color {
                    Text("•")
                    Image(systemName: SFSymbols.circleFill)
                        .foregroundStyle(color)
                    Text(item.color.title)
                }
            }
            .font(.caption2)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(.secondary)
        }
    }
    
    var ItemImage: some View {
        PrimaryImageView(
            image: item.primaryImage,
            size: Constants.Image.listItemDefault,
            isExpandable: false
        )
    }
}

private extension ItemListItemView {
    @ViewBuilder
    var StatusCTA: some View {
        switch style {
        case .installation(let room):
            SmallCTA(
                isButton: false,
                type: .outline,
                size: .small,
                leadingIcon: SFSymbols.houseFill,
                text: room.displayName,
                semibold: false
            )
        default:
            LocationStatusCTA(location: item.location)
        }
    }
}

// MARK: - LeadingContent

private extension ItemListItemView {
    var LeadingContent: some View {
        HStack(spacing: .zero) {
            ItemImage
        }
        .padding(.trailing, 8)
    }
}

// MARK: - TrailingContent

private extension ItemListItemView {
    var TrailingContent: some View {
        HStack(spacing: 4) {
            if let _ = item.essentialGroupId {
                Text(essentialsEmoji)
                    .font(.caption2)
            }
            
            if let action {
                switch style {
                case .inventoryList:
                    Button {
                        action(ItemListItemAction.copyItem(item))
                    } label: {
                        Image(systemName: SFSymbols.docOnDoc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                case .essentialsGroup, .listRoom:
                        Button {
                            action(ItemListItemAction.removeItem(item))
                        } label: {
                            Image(systemName: SFSymbols.xmark)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                case .addToDocument, .installation:
                    Button {
                        action(
                            isSelected ?
                            ItemListItemAction.multiSelectDeselection(item)
                            : ItemListItemAction.multiSelectSelection(item)
                        )
                    } label: {
                        if isSelected {
                            Image(systemName: SFSymbols.checkmarkCircleFill)
                                .foregroundStyle(.red)
                        } else {
                            Circle()
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(16)
                default:
                    EmptyView()
                }
            }
        }
    }
}
