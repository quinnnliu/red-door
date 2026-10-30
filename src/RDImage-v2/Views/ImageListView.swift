//
//  ImageListView.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/29/26.
//

import PhotosUI
import SwiftUI

private let imageGridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)

// MARK: - ImageListView

struct ImageListView: View {
    let images: [RDImage]
    var isExpandable: Bool = true

    private var emptySlotIndices: [Int] {
        Array(0..<max(0, Constants.Image.maxSecondaryImages - images.count))
    }

    init(
        _ images: [RDImage],
        isExpandable: Bool = true
    ) {
        self.images = images
        self.isExpandable = isExpandable
    }

    var body: some View {
        LazyVGrid(columns: imageGridColumns, spacing: 8) {
            ForEach(images.prefix(Constants.Image.maxSecondaryImages)) { image in
                ImageView(image: image, useThumbnail: true, isExpandable: isExpandable)
            }

            // Invisible squares keep the grid the same size however many images there are.
            ForEach(emptySlotIndices, id: \.self) { _ in
                Color.clear.aspectRatio(1, contentMode: .fit)
            }
        }
        .frame(maxWidth: Constants.Screen.screenWidthPadding)
    }
}

// MARK: - ImageListEditorAction

enum ImageListEditorAction {
    case add(_ image: UIImage)
    case replace(id: String, _ image: UIImage)
    case delete(id: String)
}

// MARK: - ImageListEditor

/// An editable grid that always shows `Constants.Image.maxSecondaryImages` slots:
/// the existing images first, then empty placeholders that add a new image.
struct ImageListEditor: View {
    let images: [RDImage]
    let action: (Any?) -> Void

    private var emptySlotIndices: [Int] {
        Array(0..<max(0, Constants.Image.maxSecondaryImages - images.count))
    }

    init(
        _ images: [RDImage],
        action: @escaping (Any?) -> Void
    ) {
        self.images = images
        self.action = action
    }
    
    var body: some View {
        LazyVGrid(columns: imageGridColumns, spacing: 8) {
            ForEach(images.prefix(Constants.Image.maxSecondaryImages)) { image in
                ImageEditor(image: image, useThumbnail: true) { editorAction in
                    handleAction(editorAction, for: image.id)
                }
            }

            ForEach(emptySlotIndices, id: \.self) { _ in
                ImageEditor(image: nil, useThumbnail: true, showsDelete: false) { editorAction in
                    handleAction(editorAction, for: nil)
                }
            }
        }
        .frame(maxWidth: Constants.Screen.screenWidth)
    }

    private func handleAction(_ editorAction: Any?, for id: String?) {
        guard let editorAction = editorAction as? ImageEditorAction else { return }
        switch editorAction {
        case .newImage(let uiImage):
            if let id {
                action(ImageListEditorAction.replace(id: id, uiImage))
            } else {
                action(ImageListEditorAction.add(uiImage))
            }
        case .deleteImage:
            if let id { action(ImageListEditorAction.delete(id: id)) }
        }
    }
}
