//
//  PrimaryImageView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/10/26.
//

import CachedAsyncImage
import PhotosUI
import SwiftUI

enum ImageSourceEnum: String, Identifiable {
    var id: String {
        rawValue
    }

    case library, camera
}

// MARK: - ItemImageView

struct PrimaryImageView: View {
    let image: RDImage?
    
    @State private var selectedImage: RDImage?

    var body: some View {
        Button {
            if let uiImage = image?.uiImage {
                selectedImage = RDImage(uiImage: uiImage)
            } else if image?.imageURL != nil {
                selectedImage = image
            }
        } label: {
            PrimaryImageContent(image, editable: false)
        }
        .frame(width: Constants.screenWidthPadding / 2, height: Constants.screenWidthPadding / 2)
        .clipped()
        .expandImageOverlay(image)
        .fullScreenCover(item: $selectedImage) { _ in
            PrimaryImageOverlay(selectedImage)
        }
        .contentShape(Rectangle())
        .cornerRadius(12)
    }
}

// MARK: - ItemImageEditor

struct PrimaryImageEditor: View {
    let image: RDImage?
    let action: (Any?) -> ()

    @State private var showEditAlert = false
    @State private var activeSheet: ImageSourceEnum?
    @State private var showAlert: Bool = false
    @State private var alertText: String = ""
    
    var body: some View {
        Button {
            showEditAlert = true
        } label: {
            PrimaryImageContent(image, editable: true)
        }
        .alert(alertText, isPresented: $showAlert, actions: { })
        .alert(
            (image?.imageExists ?? false) ? "Update Image" : "Upload Image",
            isPresented: $showEditAlert
        ) {
            Button("Library") { activeSheet = .library }
            Button("Camera")  { activeSheet = .camera }
            Button("Delete", role: .destructive) {
                guard var deletedImage = image else {
                    showEditAlert = false
                    alertText = "Error deleting image, please try again"
                    showAlert = true
                    return
                }
                deletedImage.imageType = .delete
                action(ImageEditorAction.deleteImage(deletedImage))
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .library:
                SingleLibraryPickerV2(action: handleResult(_:))
            case .camera:
                SingleCameraPickerV2(action: handleResult(_:))
            }
        }
        .frame(width: Constants.screenWidthPadding / 2, height: Constants.screenWidthPadding / 2)
        .clipped()
        .expandImageOverlay(image)
        .contentShape(Rectangle())
        .cornerRadius(12)
    }

    private func handleResult(_ result: RDImage?) {
        if let image = result {
            action(ImageEditorAction.newImage(image))
        }
        activeSheet = nil
    }
    
    enum ImageEditorAction {
        case newImage(_ image: RDImage)
        case deleteImage(_ image: RDImage)
    }
}

// MARK: - ItemImageContent (shared rendering)

private struct PrimaryImageContent: View {
    let image: RDImage?
    let editable: Bool
    
    init(_ image: RDImage?, editable: Bool) {
        self.image = image
        self.editable = editable
    }

    var body: some View {
        Group {
            if let uiImage = image?.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let imageUrl = image?.imageURL {
                CachedAsyncImage(url: imageUrl) { img in
                    img
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    PlaceholderRectangle(isLoading: true)
                }
            } else {
                PlaceholderRectangle()
            }
        }
    }

    func PlaceholderRectangle(isLoading: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .foregroundColor(Color(.systemGray5))
            .overlay {
                if isLoading {
                    ProgressView()
                } else if editable {
                    Image(systemName: SFSymbols.photoBadgePlus)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.secondary)
                }
            }
    }
}

private struct ExpandImageOverlayModifier: ViewModifier {
    let image: RDImage?
    @State private var showImageOverlay = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if image != nil {
                    Button {
                        showImageOverlay = true
                    } label: {
                        Image(systemName: SFSymbols.arrowDownLeftAndArrowUpRight)
                            .font(.caption2)
                            .padding(8)
                            .foregroundStyle(.white)
                            .background(.gray)
                            .frame(24)
                            .clipShape(.circle)
                    }
                    .offset(x: -8, y: 8)
                }
            }
            .sheet(isPresented: $showImageOverlay) {
                PrimaryImageOverlay(image)
            }
    }
}

private extension View {
    func expandImageOverlay(_ image: RDImage?) -> some View {
        modifier(ExpandImageOverlayModifier(image: image))
    }
}

private struct PrimaryImageOverlay: View {
    @Environment(\.dismiss) private var dismiss
    let image: RDImage?
    
    init(_ image: RDImage?) {
        self.image = image
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismiss()
                }
            
            if let uiImage = image?.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(8)
                    .shadow(radius: 10)
                
            } else if let imageURL = image?.imageURL {
                CachedAsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(8)
                        .shadow(radius: 10)
                } placeholder: {
                    ProgressView("Loading Image...")
                }
            }
            
            BackButton()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .frameTopPadding()
                .frameHorizontalPadding()
        }
    }
}
