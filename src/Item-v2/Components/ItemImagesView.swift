//
//  ItemImagesView.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/30/26.
//

import SwiftUI

/// Read-only images for an item's detail screens: the primary image, with a grid
/// of its secondary images beside it when it has any.
struct ItemImagesView: View {
    let item: ItemV2

    var body: some View {
        if let secondaryImages = item.secondaryImages, !secondaryImages.isEmpty {
            HStack(spacing: Constants.Padding(1)) {
                ImageView(image: item.primaryImage)
                    .frame(Constants.Image.detail - Constants.Padding(0.5))

                ImageListView(secondaryImages)
            }
        } else {
            ImageView(image: item.primaryImage)
                .frame(Constants.Image.detail)
        }
    }
}
