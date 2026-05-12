//
//  ItemImageV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/27/26.
//

import AVFoundation
import CachedAsyncImage
import PhotosUI
import SwiftUI

// MARK: - ItemImageView

struct ItemImageView: View {
    let image: RDImage
    @Binding var selectedImage: RDImage?
    @Binding var isImageSelected: Bool

    var body: some View {
        Button {
            guard image.imageExists else { return }
            if image.imageURL != nil {
                selectedImage = image
            } else if let uiImage = image.uiImage {
                selectedImage = RDImage(uiImage: uiImage)
            }
            isImageSelected = true
        } label: {
            ItemImageContent(image: image, showUploadIcon: false)
        }
        .frame(width: Constants.screenWidthPadding / 2, height: Constants.screenWidthPadding / 2)
        .contentShape(Rectangle())
        .cornerRadius(12)
    }
}

// MARK: - ItemImageEditor

struct ItemImageEditor: View {
    @Binding var image: RDImage

    @State private var showEditAlert = false
    @State private var activeSheet: ImageSourceEnum?

    var body: some View {
        Button {
            showEditAlert = true
        } label: {
            ItemImageContent(image: image, showUploadIcon: true)
        }
        .alert(
            image.imageExists ? "Update Image" : "Upload Image",
            isPresented: $showEditAlert
        ) {
            Button("Library") { activeSheet = .library }
            Button("Camera")  { activeSheet = .camera }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .library:
                SingleLibraryPicker(primaryRDImage: $image) { activeSheet = nil }
            case .camera:
                SingleCameraPicker(primaryRDImage: $image) { activeSheet = nil }
            }
        }
        .frame(width: Constants.screenWidthPadding / 2, height: Constants.screenWidthPadding / 2)
        .contentShape(Rectangle())
        .cornerRadius(12)
    }
}

// MARK: - ItemImageContent (shared rendering)

private struct ItemImageContent: View {
    let image: RDImage
    let showUploadIcon: Bool

    var body: some View {
        if let imageUrl = image.imageURL {
            CachedAsyncImage(url: imageUrl) { img in
                img
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .foregroundStyle(.gray.opacity(0.3))
            }
        } else if let uiImage = image.uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(Color(.systemGray5))
                .overlay {
                    if showUploadIcon {
                        Image(systemName: SFSymbols.photoBadgePlus)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.secondary)
                    }
                }
        }
    }
}
