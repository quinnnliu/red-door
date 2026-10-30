//
//  EditItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import SwiftUI

struct EditItemView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator.self) private var coordinator: NavigationCoordinator

    @State private var viewModel: EditItemViewModel
    var onDelete: (() -> Void)?

    // Delete
    @State private var showDeleteAlert: Bool = false

    init(viewModel: EditItemViewModel, onDelete: (() -> Void)? = nil) {
        self._viewModel = State(initialValue: viewModel)
        self.onDelete = onDelete
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    VStack(alignment: .center, spacing: 6) {
                        TopBar()
                        NicknameEntry
                    }

                    ImageSection

                    EditItemDetailSection(
                        description: $viewModel.updatedItem.description,
                        color: $viewModel.updatedItem.color,
                        material: $viewModel.updatedItem.material,
                        type: $viewModel.updatedItem.type,
                        value: $viewModel.updatedItem.value,
                        brand: $viewModel.updatedItem.brand,
                        purchaseLocation: $viewModel.updatedItem.purchaseLocation,
                        datePurchased: $viewModel.updatedItem.datePurchased,
                        dimensions: $viewModel.updatedItem.dimensions
                    )

                    EssentialsGroupPicker(
                        groups: viewModel.availableGroups,
                        selected: $viewModel.selectedGroup
                    )
                    
                    AttentionPicker(
                        needsAttention: $viewModel.updatedItem.attention,
                        attentionDescription: $viewModel.updatedItem.attentionDescription
                    )

                    Spacer()

                    if let reason = viewModel.originalItem.deleteErrorReason?.errorDescription {
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    RDButton(style: .red, size: .default, leadingIcon: "trash", label: "Delete Item", fullWidth: false) {
                        showDeleteAlert = true
                    }
                    .disabled(!viewModel.originalItem.canDelete)
                    .alert("Confirm Delete", isPresented: $showDeleteAlert) {
                        Button(role: .destructive) {
                            deleteItem()
                        } label: {
                            Text("Delete")
                        }
                        Button(role: .cancel) {} label: {
                            Text("Cancel")
                        }
                    }
                }
                .frameTop()
                .frameHorizontalPadding()
                .frameTopPadding()
            }
            .toolbar(.hidden)
            .scrollDismissesKeyboard(.automatic)

            if viewModel.isLoading {
                FullScreenProgressView(label: viewModel.isDeleting ? "Deleting Item..." : "Saving Item...")
            }
        }
        .task {
            await viewModel.loadGroups()
        }
        .alert("Error", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    // MARK: - Top Bar

    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(
            leadingView: {
                RDButton(style: .red, size: .icon, leadingIcon: SFSymbols.xmark, fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                ItemNameEntry
            },
            trailingView: {
                RDButton(style: .red, size: .icon, leadingIcon: "checkmark", fullWidth: false) {
                    saveItem()
                }
                .clipShape(Circle())
            }
        )
    }

    // MARK: - Item Name Entry

    var ItemNameEntry: some View {
        TextField("Item Name", text: $viewModel.updatedItem.baseName)
            .padding(6)
            .background(Color(.systemGray5))
            .cornerRadius(Constants.CornerRadius.medium)
            .multilineTextAlignment(.center)
    }
    
    var NicknameEntry: some View {
        HStack(spacing: 4) {
            if viewModel.updatedItem.nickname != nil {
                Text("Nickname:")
            }
            TextField("Nickname (optional)", text: Binding(
                get: { viewModel.updatedItem.nickname ?? "" },
                set: { viewModel.updatedItem.nickname = $0.isEmpty ? nil : $0 }
            ))
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: Constants.Screen.screenWidth / 2, alignment: .center)
    }

    // MARK: - Image Section

    private var ImageSection: some View {
        HStack(spacing: Constants.Padding(1)) {
            ImageEditor(image: viewModel.updatedItem.primaryImage) { action in
                handleImageAction(action)
            }
            .frame(Constants.Image.detail - Constants.Padding(0.5))

            ImageListEditor(viewModel.updatedItem.secondaryImages ?? []) { action in
                handleSecondaryImageAction(action)
            }
        }
    }

    // MARK: - Helper Functions

    private func handleImageAction(_ actionArg: Any?) {
        guard let action = actionArg as? ImageEditorAction else { return }
        switch action {
        case .newImage(let image):
            viewModel.setPrimaryImage(image)
        case .deleteImage:
            viewModel.clearPrimaryImage()
        }
    }

    private func handleSecondaryImageAction(_ actionArg: Any?) {
        guard let action = actionArg as? ImageListEditorAction else { return }
        switch action {
        case .add(let image):
            viewModel.addSecondaryImage(image)
        case .replace(let id, let image):
            viewModel.replaceSecondaryImage(id: id, with: image)
        case .delete(let id):
            viewModel.removeSecondaryImage(id: id)
        }
    }

    private func saveItem() {
        Task {
            if await viewModel.save() {
                dismiss()
            }
        }
    }

    private func deleteItem() {
        Task {
            if await viewModel.delete() {
                onDelete?()
                coordinator.resetSelectedPath()
            }
        }
    }
}
