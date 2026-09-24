//
//  ItemListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import SwiftUI

enum ItemListItemStyle {
    case inventoryList
    case addItemToDocument
    case essentialsGroup
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
    @State private var isSelected: Bool
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
        self._isSelected = State(initialValue: isSelected)
        self.action = action
    }

    // MARK: Body
    var body: some View {
        Group {
            switch style {
            case .inventoryList, .addItemToDocument:
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
        HStack(spacing: 12) {
            LeadingContent
            
            BodyContent

            Spacer()

            TrailingContent
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

// MARK: - BodyContent
private extension ItemListItemView {
    var BodyContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(item.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if item.location.status != .inStorage {
                    Text("• \(item.location.status.displayTitle)")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            HStack(spacing: 4) {
                Image(systemName: item.type.icon ?? SFSymbols.ellipsis)
                Text("•")
                Text(item.material.title)
                if let color = item.color.color {
                    Text("•")
                    Image(systemName: SFSymbols.circleFill)
                        .foregroundStyle(color)
                }
            }
            .font(.footnote)
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

// MARK: - LeadingContent

private extension ItemListItemView {
    var LeadingContent: some View {
        HStack(spacing: 12) {
            
            if style == .addItemToDocument, let action = action {
                Button {
                    action(
                        isSelected ?
                        ItemListItemAction.multiSelectDeselection(item)
                        : ItemListItemAction.multiSelectSelection(item)
                    )
                    isSelected.toggle()
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
            }
            
            ItemImage
        }
    }
}

// MARK: - TrailingContent

private extension ItemListItemView {
    var TrailingContent: some View {
        HStack(spacing: 12) {
            
            if let _ = item.essentialGroupId {
                Text(essentialsEmoji)
                    .font(.caption)
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
                case .essentialsGroup:
                    Button {
                        action(ItemListItemAction.removeItem(item))
                    } label: {
                        Image(systemName: SFSymbols.xmark)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                default:
                    EmptyView()
                }
            }
        }
    }
}
