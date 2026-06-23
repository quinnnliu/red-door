//
//  ItemDocumentListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import CachedAsyncImage
import SwiftUI

struct ItemDocumentListItemView: View {
    let item: ItemV2
    private let imageSize: CGFloat = Constants.screenWidth / 7

    // MARK: Body
    var body: some View {
        HStack(spacing: 12) {
            ItemListItemImage(item.primaryImage)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(item.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if item.status != .inStorage {
                        Text("• \(item.status.displayTitle)")
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

            if let _ = item.essentialGroupId {
                Image(systemName: SFSymbols.starCircleFill)
                    .foregroundStyle(.yellow)
                    .padding(.trailing, 6)
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}
