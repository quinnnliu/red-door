//
//  ItemListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import CachedAsyncImage
import SwiftUI

struct ItemListItemView: View {
    let item: ItemV2
    private let imageSize: CGFloat = Constants.screenWidth / 7

    private var typeIcon: String {
        switch item.type {
        case .chair: return "chair.fill"
        case .desk, .table: return "table.furniture.fill"
        case .lamp: return "lamp.floor.fill"
        case .accessories: return "tag.fill"
        case .misc: return "ellipsis.circle"
        }
    }

    // MARK: Body
    var body: some View {
        HStack(spacing: 12) {
            ItemImage()

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if item.status != .inStorage {
                        Text("• \(item.status.displayTitle)")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: typeIcon)
                    Text("•")
                    Text(item.material.title)
                    Text("•")
                    Image(systemName: SFSymbols.circleFill)
                        .foregroundStyle(item.color.color)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if item.isEssential {
                Image(systemName: SFSymbols.starCircleFill)
                    .foregroundStyle(.yellow)
                    .padding(.trailing, 6)
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }

    // MARK: Item Image
    @ViewBuilder
    private func ItemImage() -> some View {
        if let url = item.primaryImage.imageURL {
            CachedAsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView().frame(imageSize)
                case .success(let image):
                    image.resizable().scaledToFill().frame(imageSize).cornerRadius(6)
                case .failure:
                    Image(systemName: SFSymbols.photoBadgePlus).frame(imageSize).foregroundStyle(.secondary)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(systemName: SFSymbols.photo)
                .frame(imageSize)
                .foregroundStyle(.secondary)
        }
    }
}
