//
//  ModelPrimaryImage.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/10/25.
//

import AVFoundation
import CachedAsyncImage
import Foundation
import PhotosUI
import SwiftUI

struct ModelPrimaryImage: View {
    @State private var showEditAlert: Bool = false
    @State private var activeSheet: ImageSourceEnum?

    @Binding var primaryRDImage: RDImage
    @Binding var selectedRDImage: RDImage?
    @Binding var isImageSelected: Bool
    // TODO: don't need this to be a binding
    @Binding var isEditing: Bool

    var body: some View {
        Button {
            if isEditing {
                showEditAlert = true
            } else {
                if primaryRDImage.imageURL != nil {
                    selectedRDImage = primaryRDImage
                } else if let uiImage = primaryRDImage.uiImage {
                    selectedRDImage = RDImage(uiImage: uiImage)
                }
                isImageSelected = true
            }
        } label: {
            if let imageUrl = primaryRDImage.imageURL {
                CachedAsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .foregroundStyle(.gray.opacity(0.3))
                }
            } else if let uiImage = primaryRDImage.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else { // no image selected
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color(.systemGray5))
                    .frame(width: Constants.screenWidthPadding / 2, height: Constants.screenWidthPadding / 2)
                    .overlay(Image(systemName: SFSymbols.photoBadgePlus)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.secondary)
                    )
            }
        }
        .alert(
            primaryRDImage.imageURL != URL(string: "") ? "Upload Method" : "Update Image",
            isPresented: $showEditAlert
        ) {
            EditPhotoAlert()
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .library:
                SingleLibraryPicker(primaryRDImage: $primaryRDImage) {
                    activeSheet = nil
                }
            case .camera:
                SingleCameraPicker(primaryRDImage: $primaryRDImage) {
                    activeSheet = nil
                }
            }
        }
        .frame(width: Constants.screenWidthPadding / 2, height: Constants.screenWidthPadding / 2)
        .contentShape(Rectangle())
        .cornerRadius(12)
    }

    // MARK: Edit Photo Alert

    @ViewBuilder
    private func EditPhotoAlert() -> some View {
        Group {
            Button(role: .none) {
                activeSheet = .library
            } label: {
                Text("Library")
            }

            Button(role: .none) {
                activeSheet = .camera
            } label: {
                Text("Camera")
            }

            Button(role: .cancel) {} label: {
                Text("Cancel")
            }
        }
    }
}

//
// #Preview {
//    @Previewable @State var primaryImage: UIImage? = nil
//    ModelPrimaryImage(primaryImage: $primaryImage)
// }
