//
//  CreateItemViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import SwiftUI
import PhotosUI

struct CreateItemViewV2: View {
    @State private var viewModel: CreateItemsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isEditing: Bool = true
    
    var fromTemplate: Bool { viewModel.templateState != nil }

    init(template: ItemV2? = nil) {
        _viewModel = State(initialValue: CreateItemsViewModel(template: template))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                TopBar()
                
                ScrollView {
                    if fromTemplate {
                        PrimaryImageView(image: viewModel.itemState.primaryImage)
                    } else {
                        PrimaryImageEditor(image: viewModel.itemState.primaryImage) { action in
                            handleImageAction(action)
                        }
                    }
                    
                    ItemCountPicker
                        .padding(8)
                        .background(.gray.opacity(0.2))
                        .cornerRadius(8)

                    EssentialsGroupRow

                    AttentionPicker(
                        needsAttention: $viewModel.itemState.attention,
                        attentionDescription: $viewModel.itemState.attentionDescription
                    )

                    StorageLocationRow
                                        
                    ItemDetailsSection
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.automatic)
                .ignoresSafeArea(.keyboard)

                Spacer()

                RDButton(
                    style: .red,
                    size: .default,
                    leadingIcon: "plus",
                    label: "Add Items to Inventory"
                ) {
                    Task {
                        if await viewModel.createItems() { dismiss() }
                    }
                }
                .disabled(viewModel.selectedStorageLocation == nil)
            }
            .toolbar(.hidden)
            .frameTop()
            .frameHorizontalPadding()
            
            if viewModel.isLoading {
                FullScreenProgressView(label: "Saving Items")
            }
        }
        .task {
            await viewModel.loadGroups()
            await viewModel.loadStorageLocations()
        }
        .overlay(
            ModelRDImageOverlay(selectedRDImage: viewModel.selectedRDImage, isImageSelected: $viewModel.isImageSelected)
                .animation(Constants.Animation.snappy, value: viewModel.isImageSelected)
        )
    }
    
    // MARK: - Top Bar
    
    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(
            leadingView: {
                RDButton(style: .red, size: .icon, leadingIcon: "xmark", fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                ModelNameEntry
            },
            trailingView: {
                Spacer().frame(24)
            }
        )
    }
    
    // MARK: Model Name Entry
    
    var ModelNameEntry: some View {
        TextField("Item Name", text: $viewModel.itemState.baseName)
            .foregroundStyle(fromTemplate ? .gray : .primary)
            .padding(6)
            .background(viewModel.isImageSelected ? Color.clear : Color(.systemGray5))
            .cornerRadius(Constants.CornerRadius.medium)
            .multilineTextAlignment(.center)
            .disabled(viewModel.templateState != nil)
    }
    
    // MARK: Item Count Picker

    private var ItemCountPicker: some View {
        Stepper(value: $viewModel.itemCount, in: 1...500) {
            Text("Number of Items: \(viewModel.itemCount)")
                .font(.headline)
                .foregroundStyle(.red)
                .bold()
        }
    }
    
    // MARK: ItemDetailsSection
    private var ItemDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if fromTemplate {
                HStack {
                    Image(systemName: SFSymbols.lockFill)
                    Text("Details Locked")
                }
                .font(.caption)
            }
            
            EditItemDetailSection(
                description: $viewModel.itemState.description,
                color: $viewModel.itemState.color,
                material: $viewModel.itemState.material,
                type: $viewModel.itemState.type,
                value: $viewModel.itemState.value,
                brand: $viewModel.itemState.brand,
                purchaseLocation: $viewModel.itemState.purchaseLocation,
                datePurchased: $viewModel.itemState.datePurchased,
                dimensions: $viewModel.itemState.dimensions
            )
            .disabled(viewModel.templateState != nil)
        }
        .padding(fromTemplate ? 8 : .zero)
        .background(fromTemplate ? .gray.opacity(0.2) : .clear)
        .cornerRadius(8)
    }

    // MARK: Storage Location Row

    private var StorageLocationRow: some View {
        StorageLocationPicker(
            locations: viewModel.storageLocations,
            selected: $viewModel.selectedStorageLocation,
            refreshAction: { Task { await viewModel.refreshStorageLocations() } }
        )
    }
    
    // MARK: EssentialsGroupRow

    private var EssentialsGroupRow: some View {
        EssentialsGroupPicker(
            groups: viewModel.availableGroups,
            selected: $viewModel.selectedGroup
        )
    }

    // MARK: Image Action Handler

    private func handleImageAction(_ actionArg: Any?) {
        guard let action = actionArg as? ImageEditorAction else { return }
        switch action {
        case .newImage(let image):
            viewModel.itemState.primaryImage = image
        case .deleteImage:
            // Nothing is uploaded yet when creating, so just reset instead of keeping a `.delete` image
            viewModel.itemState.primaryImage = RDImage()
        }
    }
}


#Preview {
    CreateItemViewV2()
}

