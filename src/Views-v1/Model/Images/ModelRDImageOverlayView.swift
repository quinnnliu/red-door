//
//  ModelRDImageOverlayView.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/28/25.
//

import CachedAsyncImage
import SwiftUI

struct ModelRDImageOverlay: View {
    let selectedRDImage: RDImage?
    @Binding var isImageSelected: Bool

    var body: some View {
        if let selectedRDImage {
            if isImageSelected {
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        isImageSelected = false
                    }

                if let uiImage = selectedRDImage.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(8)
                        .shadow(radius: 10)
                } else if let imageURL = selectedRDImage.imageURL {
                    CachedAsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .cornerRadius(8)
                            .shadow(radius: 10)
                    } placeholder: {
                        Rectangle()
                            .foregroundStyle(.gray.opacity(0.3))
                    }
                }
            }
        }
    }
}
