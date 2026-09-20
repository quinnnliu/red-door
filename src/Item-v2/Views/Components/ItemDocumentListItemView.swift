//
//  ItemDocumentListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import CachedAsyncImage
import SwiftUI

enum ItemListItemStyle {
    case inventoryList
    case addItemToDocument
    case addItemToRoom
    case essentialsGroup
}

enum ItemDocumentListItemAction {
    case copyItem(ItemV2)
    case removeItem(ItemV2)
}

struct ItemDocumentListItemView: View {
    let item: ItemV2
    var style: ItemListItemStyle
    let essentialsEmoji: String
    var action: ((Any) -> Void)? = nil

    private let imageSize: CGFloat = Constants.screenWidth / 7
    
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
        HStack(spacing: 12) {
            ThumbnailImageView(item.primaryImage)

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
        .cornerRadius(8)
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
                    Menu {
                        Button("Create Copy", systemImage: "doc.on.doc") {
                            action(ItemDocumentListItemAction.copyItem(item))
                        }
                    } label: {
                        RDButton(variant: .secondary, size: .icon, leadingIcon: SFSymbols.ellipsis, fullWidth: false) { }
                            .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
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
