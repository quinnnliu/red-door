//
//  ItemListItemImage.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import SwiftUI
import CachedAsyncImage


struct ItemListItemImage: View {
    let image: RDImage
    let size: CGFloat
    
    init(_ image: RDImage, size: CGFloat = 48) {
        self.image = image
        self.size = size
    }
    
    var body: some View {
        Group {
            if image.imageExists {
                if let image = image.uiImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let imageUrl = image.imageURL {
                    CachedAsyncImage(url: imageUrl) { phase in
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
            } else {
                Color.gray
                    .overlay(
                        Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(size)
        .clipped()
        .cornerRadius(6)
    }
}
