//
//  PrimaryImageView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/10/26.
//

import Kingfisher
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
    let size: CGFloat
    let isExpandable: Bool
    
    @State private var expandedImage: RDImage?
    
    init(
        image: RDImage?,
        expandedImage: RDImage? = nil,
        size: CGFloat? = Constants.Screen.screenWidthPadding / 2,
        isExpandable: Bool = true
    ) {
        self.image = image
        self.expandedImage = expandedImage
        self.size = size ?? Constants.Screen.screenWidthPadding / 2
        self.isExpandable = isExpandable
    }

    var body: some View {
        Group {
            if isExpandable {
                Button {
                    if let uiImage = image?.uiImage {
                        expandedImage = RDImage(uiImage: uiImage)
                    } else if image?.imageURL != nil {
                        expandedImage = image
                    }
                } label: {
                    PrimaryImageContent(image, editable: false, size: size)
                }
            } else {
                PrimaryImageContent(image, editable: false, size: size)
            }
        }
        .frame(size)
        .clipped()
        .expandImageOverlay(image, isEnabled: isExpandable)
        .sheet(item: $expandedImage) { image in
            PrimaryImageOverlay(image)
        }
        .contentShape(Rectangle())
        .cornerRadius(12)
    }
}

// MARK: - ImageEditorAction

enum ImageEditorAction {
    case newImage(_ image: RDImage)
    case deleteImage(_ image: RDImage)
}

// MARK: - ItemImageEditor

struct PrimaryImageEditor: View {
    let image: RDImage?
    let action: (Any?) -> ()
    let size: CGFloat = Constants.Screen.screenWidthPadding / 2

    @State private var showEditAlert = false
    @State private var activeSheet: ImageSourceEnum?
    @State private var showAlert: Bool = false
    @State private var alertText: String = ""
    
    var body: some View {
        Button {
            showEditAlert = true
        } label: {
            PrimaryImageContent(image, editable: true, size: size)
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
        .expandImageOverlay(image)
        .contentShape(Rectangle())
    }

    private func handleResult(_ result: RDImage?) {
        if let image = result {
            action(ImageEditorAction.newImage(image))
        }
        activeSheet = nil
    }
    
    
}

// MARK: - ItemImageContent (shared rendering)

private struct PrimaryImageContent: View {
    let image: RDImage?
    let editable: Bool
    let size: CGFloat
    
    init(_ image: RDImage?, editable: Bool, size: CGFloat) {
        self.image = image
        self.editable = editable
        self.size = size
    }

    var body: some View {
        Group {
            if let uiImage = image?.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else if let thumbnailURL = image?.thumbnailURL, size < Constants.Screen.screenWidth / 2 {
                RDImageView(url: thumbnailURL)
            } else if let imageUrl = image?.imageURL {
                RDImageView(url: imageUrl)
            } else {
                RDImagePlaceholder(content: .empty(editable: editable))
            }
        }
        .frame(size)
        .clipped()
        .cornerRadius(12)
    }
}

private struct ExpandImageOverlayModifier: ViewModifier {
    let image: RDImage?
    let isEnabled: Bool
    
    init(image: RDImage?, isEnabled: Bool = true) {
        self.image = image
        self.isEnabled = isEnabled
    }
    
    @State private var showImageOverlay = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if image != nil, isEnabled {
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
    func expandImageOverlay(_ image: RDImage?, isEnabled: Bool = true) -> some View {
        modifier(ExpandImageOverlayModifier(image: image, isEnabled: isEnabled))
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
                KFImage(imageURL)
                    .placeholder { ProgressView("Loading Image...") }
                    .fade(duration: 0.2)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(8)
                    .shadow(radius: 10)
            }
            
            BackButton(icon: SFSymbols.xmark)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .frameTopPadding()
                .frameHorizontalPadding()
        }
    }
}
