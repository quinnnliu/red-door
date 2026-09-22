//
//  ItemDocumentListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import SwiftUI

enum ItemListItemStyle {
    case inventoryList
    case addItemToDocument
    case addItemToRoom
    case essentialsGroup
}

enum ItemDocumentListItemAction {
    case navigate(ItemV2)
    case copyItem(ItemV2)
    case removeItem(ItemV2)
}

struct ItemDocumentListItemView: View {
    let item: ItemV2
    var style: ItemListItemStyle
    let essentialsEmoji: String
    var action: ((Any) -> Void)? = nil

    init(
        item: ItemV2,
        style: ItemListItemStyle = .inventoryList,
        essentialsEmoji: String = "⭐️",
        action: ((Any) -> Void)? = nil
    ) {
        self.item = item
        self.style = style
        self.essentialsEmoji = essentialsEmoji
        self.action = action
    }

    // MARK: Body
    var body: some View {
        Group {
            if style == .inventoryList, let action {
                Button {
                    action(ItemDocumentListItemAction.navigate(item))
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
            PrimaryImageView(image: item.primaryImage, size: Constants.Image.listItemDefault, isExpandable: false)

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

            Spacer()

            TrailingContent
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

private extension ItemDocumentListItemView {
    var TrailingContent: some View {
        HStack(spacing: 8) {
            
            if let _ = item.essentialGroupId {
                Text(essentialsEmoji)
                    .font(.caption)
            }
            
            if let action {
                switch style {
                case .inventoryList:
                    Button {
                        action(ItemDocumentListItemAction.copyItem(item))
                    } label: {
                        Image(systemName: SFSymbols.docOnDoc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                case .essentialsGroup:
                    Button {
                        action(ItemDocumentListItemAction.removeItem(item))
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
