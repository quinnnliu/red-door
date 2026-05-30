//
//  ItemImage.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/20/25.
//

import SwiftUI
import CachedAsyncImage

struct ItemImage: View {
    @Binding var itemImage: RDImage?
    private let isEditing: Bool
    var size: CGFloat = 48
    @State private var editingImage: RDImage
    
    // Optional bindings for overlay functionality
    var selectedRDImage: Binding<RDImage?>? = nil
    var isImageSelected: Binding<Bool>? = nil

    @State private var showEditAlert: Bool = false
    @State private var activeSheet: ImageSourceEnum?

    init(itemImage: Binding<RDImage?>, isEditing: Bool, size: CGFloat = Constants.screenWidthPadding / 2, selectedRDImage: Binding<RDImage?>? = nil, isImageSelected: Binding<Bool>? = nil) {
        _itemImage = itemImage
        self.isEditing = isEditing
        self.size = size
        self.editingImage = itemImage.wrappedValue ?? RDImage()
        self.selectedRDImage = selectedRDImage
        self.isImageSelected = isImageSelected
    }
    
    // MARK: Body
    var body: some View {
        Button {
            if isEditing {
                showEditAlert = true
            } else {
                // Show overlay if bindings are provided
                if let selectedRDImage = selectedRDImage, let isImageSelected = isImageSelected {
                    if let image = itemImage {
                        if image.imageURL != nil {
                            selectedRDImage.wrappedValue = image
                        } else if let uiImage = image.uiImage {
                            selectedRDImage.wrappedValue = RDImage(uiImage: uiImage)
                        }
                        isImageSelected.wrappedValue = true
                    }
                }
            }
        } label: {
            StandardView()
                .cornerRadius(12)
        }
        .tint(.clear)
        .alert(
            editingImage.imageURL != URL(string: "") ? "Upload Method" : "Update Image",
            isPresented: $showEditAlert
        ) {
            EditPhotoAlert()
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .library:
                SingleLibraryPicker(primaryRDImage: $editingImage) {
                    itemImage = editingImage
                    activeSheet = nil
                }
            case .camera:
                SingleCameraPicker(primaryRDImage: $editingImage) {
                    itemImage = editingImage
                    activeSheet = nil
                }
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: Standard View
    @ViewBuilder
    private func StandardView() -> some View {
        if editingImage.imageURL != nil {
            CachedAsyncImage(url: editingImage.imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(size)
                case .failure:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            }
        } else if let uiImage = editingImage.uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(size)
        } else {
            Rectangle()
                .foregroundColor(Color(.systemGray5))
                .frame(size)
                .overlay(
                    Image(systemName: isEditing ? SFSymbols.photoBadgePlus : SFSymbols.photo)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.secondary)
                )
        }
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

            Button(role: .destructive) {
                editingImage.imageType = .delete
            } label: {
                Text("Delete")
            }

            Button(role: .cancel) {} label: {
                Text("Cancel")
            }
        }
    }
}