//
//  ImageView.swift
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

// MARK: - ImageView

struct ImageView: View {
    let image: RDImage?
    let useThumbnail: Bool
    let isExpandable: Bool
    
    @State private var expandedImage: RDImage? = nil
    
    /// Fills a square from the width its parent proposes; size it at the call site.
    init(
        image: RDImage?,
        useThumbnail: Bool = false,
        isExpandable: Bool = true
    ) {
        self.image = image
        self.useThumbnail = useThumbnail
        self.isExpandable = isExpandable
    }

    var body: some View {
        Group {
            if isExpandable {
                Button {
                    if image?.imageExists == true {
                        expandedImage = image
                    }
                } label: {
                    ImageContent(image, editable: false, useThumbnail: useThumbnail)
                }
            } else {
                ImageContent(image, editable: false, useThumbnail: useThumbnail)
            }
        }
        .clipped()
        .expandImageOverlay(image, isEnabled: isExpandable)
        .sheet(item: $expandedImage) { image in
            ImageOverlay(image)
        }
        .contentShape(Rectangle())
        .cornerRadius(Constants.CornerRadius.large)
    }
}

// MARK: - ImageEditorAction

enum ImageEditorAction {
    case newImage(_ image: UIImage)
    case deleteImage
}

// MARK: - ItemImageEditor

struct ImageEditor: View {
    let image: RDImage?
    let useThumbnail: Bool
    let showsDelete: Bool
    let action: (Any?) -> ()

    @State private var showEditAlert = false
    @State private var activeSheet: ImageSourceEnum?
    
    /// Fills a square from the width its parent proposes; size it at the call site.
    init(
        image: RDImage?,
        useThumbnail: Bool = false,
        showsDelete: Bool = true,
        action: @escaping (Any?) -> ()
    ) {
        self.image = image
        self.useThumbnail = useThumbnail
        self.showsDelete = showsDelete
        self.action = action
    }
    
    var body: some View {
        Button {
            showEditAlert = true
        } label: {
            ImageContent(image, editable: true, useThumbnail: useThumbnail)
        }
        .tint(.gray)
        .alert(
            (image?.imageExists ?? false) ? "Update Image" : "Upload Image",
            isPresented: $showEditAlert
        ) {
            Button("Library") { activeSheet = .library }
            Button("Camera")  { activeSheet = .camera }
            if showsDelete {
                Button("Delete", role: .destructive) {
                    action(ImageEditorAction.deleteImage)
                }
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
        .expandImageOverlay(image, isEnabled: image != nil)
        .contentShape(Rectangle())
    }

    private func handleResult(_ result: UIImage?) {
        if let image = result {
            action(ImageEditorAction.newImage(image))
        }
        activeSheet = nil
    }
}

// MARK: - ItemImageContent (shared rendering)

private struct ImageContent: View {
    let image: RDImage?
    let editable: Bool
    let useThumbnail: Bool
    
    init(_ image: RDImage?, editable: Bool, useThumbnail: Bool) {
        self.image = image
        self.editable = editable
        self.useThumbnail = useThumbnail
    }

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let uiImage = image?.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else if let thumbnailURL = image?.thumbnailURL, useThumbnail {
                    RDImageView(url: thumbnailURL)
                } else if let imageUrl = image?.imageURL {
                    RDImageView(url: imageUrl)
                } else {
                    RDImagePlaceholder(content: .empty(editable: editable))
                }
            }
            .clipped()
            .cornerRadius(Constants.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.large, style: .continuous)
                    .stroke(.primary.opacity(0.2), lineWidth: 2)
            )
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
                if image?.imageExists == true, isEnabled {
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
                ImageOverlay(image)
            }
    }
}

private extension View {
    func expandImageOverlay(_ image: RDImage?, isEnabled: Bool = true) -> some View {
        modifier(ExpandImageOverlayModifier(image: image, isEnabled: isEnabled))
    }
}

private struct ImageOverlay: View {
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
                    .cornerRadius(Constants.CornerRadius.medium)
                    .shadow(radius: 10)
                
            } else if let imageURL = image?.imageURL {
                KFImage(imageURL)
                    .placeholder { ProgressView("Loading Image...") }
                    .fade(duration: 0.2)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(Constants.CornerRadius.medium)
                    .shadow(radius: 10)
            }
            
            BackButton(icon: SFSymbols.xmark)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .frameTopPadding()
                .frameHorizontalPadding()
        }
    }
}
