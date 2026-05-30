//
//  ModelSecondaryImages.swift
//  RedDoor
//
//  Created by Quinn Liu on 7/30/25.
//

import CachedAsyncImage
import SwiftUI

struct ModelSecondaryImages: View {
    @State private var activeSheet: ImageSourceEnum?
    @State private var showAlert: Bool = false
    @State private var editIndex: Int? = nil

    @Binding var secondaryRDImages: [RDImage]
    @Binding var selectedRDImage: RDImage?
    @Binding var isImageFullScreen: Bool
    @Binding var isEditing: Bool

    var visibleImages: [RDImage] {
        secondaryRDImages.filter { $0.imageType != .delete }
    }

    var body: some View {
        Group {
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(0 ..< 2) { row in
                    GridRow {
                        ForEach(0 ..< 2) { col in
                            let index = 2 * row + col

                            SecondaryImageItem(index: index)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
        }
        .alert("Upload Type", isPresented: $showAlert) {
            EditImageAlert()
        }
        .sheet(item: $activeSheet) { activeSheet in
            if let editIndex = editIndex {
                PickerSheet(item: activeSheet, editIndex: editIndex)
                    .onDisappear {
                        self.editIndex = nil
                    }
            }
        }
        .frame(maxWidth: Constants.screenWidthPadding / 2,
               maxHeight: Constants.screenWidthPadding / 2)
    }

    // MARK: Edit Image Alert

    @ViewBuilder
    private func EditImageAlert() -> some View {
        if let index = editIndex {
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

            if isEditing {
                Button(role: .destructive) {
                    DeleteSecondaryImage(index: index)
                } label: {
                    Text("Delete")
                }
            }

            Button(role: .cancel) {} label: {
                Text("Cancel")
            }
        }
    }

    // MARK: Secondary Image Item

    @ViewBuilder
    private func SecondaryImageItem(index: Int) -> some View {
        if index < visibleImages.count {
            Button {
                if isEditing {
                    showAlert = true
                    editIndex = index
                } else {
                    if visibleImages[index].imageURL != nil {
                        selectedRDImage = visibleImages[index]
                    } else if let uiImage = visibleImages[index].uiImage {
                        selectedRDImage = RDImage(uiImage: uiImage)
                    }
                    isImageFullScreen = true
                }

            } label: {
                if let imageUrl = visibleImages[index].imageURL {
                    CachedAsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .contentShape(Rectangle())
                            .cornerRadius(12)
                    } placeholder: {
                        PlaceholderRectangle()
                    }
                } else if let uiImage = visibleImages[index].uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .contentShape(Rectangle())
                        .cornerRadius(12)
                } else {
                    PlaceholderRectangle()
                }
            }
        } else if index == visibleImages.count {
            Button {
                if isEditing {
                    showAlert = true
                    editIndex = index
                }
            } label: {
                ZStack(alignment: .center) {
                    PlaceholderRectangle()

                    Image(systemName: isEditing ? SFSymbols.plus : SFSymbols.photo)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.secondary)
                }
            }

        } else {
            PlaceholderRectangle()
        }
    }

    private func DeleteSecondaryImage(index: Int) {
        secondaryRDImages[index].imageType = .delete
        secondaryRDImages[index].uiImage = nil
        secondaryRDImages[index].imageURL = nil
    }

    @ViewBuilder
    private func PickerSheet(item: ImageSourceEnum, editIndex: Int) -> some View {
        Group {
            switch item {
            case .library:
                MultiLibraryPicker(selectedRDImages: $secondaryRDImages, editIndex: editIndex) {
                    activeSheet = nil
                }
            case .camera:
                MultiCameraPicker(selectedRDImages: $secondaryRDImages, editIndex: editIndex) {
                    activeSheet = nil
                }
            }
        }
    }

    @ViewBuilder
    private func PlaceholderRectangle() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.clear)
            .aspectRatio(1, contentMode: .fill)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.gray, lineWidth: 1)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// #Preview {
//    ModelSecondaryImages()
// }
