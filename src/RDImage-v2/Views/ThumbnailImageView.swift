//
//  ThumbnailImageView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/14/26.
//

import SwiftUI

struct ThumbnailImageView: View {
    let image: RDImage
    let size: CGFloat

    init(_ image: RDImage, size: CGFloat = 48) {
        self.image = image
        self.size = size
    }

    var body: some View {
        Group {
            if let uiImage = image.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if image.thumbnailURL != nil || image.imageURL != nil {
                RDImageView(url: image.thumbnailURL ?? image.imageURL)
            } else {
                RDImagePlaceholder(content: .empty())
            }
        }
        .frame(size)
        .clipped()
        .cornerRadius(6)
    }
}
