//
//  ItemPreviewImage.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/8/25.
//

import SwiftUI
import CachedAsyncImage

struct ItemModelImage: View {
    let item: Item
    let model: Model?
    var size: CGFloat = 48
    
    var body: some View {
        Group {
            if let itemImage = item.image, itemImage.imageExists, let imageURL = itemImage.imageURL {
                ItemCachedAsyncImage(imageURL: imageURL)
            } else if let modelImageURL = model?.primaryImage.imageURL {
                ItemCachedAsyncImage(imageURL: modelImageURL)
            } else {
                Color.gray
                    .overlay(
                        Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(size)
        .cornerRadius(8)
    }
    
    // MARK: Item Cached Async Image
    
    @ViewBuilder
    private func ItemCachedAsyncImage(imageURL: URL) -> some View {
        CachedAsyncImage(url: imageURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Color.gray
                    .overlay(
                        Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                            .foregroundColor(.white)
                    )
            @unknown default:
                Color.gray
                    .overlay(
                        Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                            .foregroundColor(.white)
                    )
            }
        }
    }
}

