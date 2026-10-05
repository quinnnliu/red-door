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

                    PrimaryImageEditor(image: viewModel.updatedItem.primaryImage) { action in
                        handleImageAction(action)
                    }

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

                    RDButton(style: .red, size: .default, leadingIcon: "trash", label: "Delete Item", fullWidth: false) {
                        showDeleteAlert = true
                    }
                    .disabled(!viewModel.canDelete)
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
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Saving Item...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
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
        TextField("Nickname (optional)", text: Binding(
            get: { viewModel.updatedItem.nickname ?? "" },
            set: { viewModel.updatedItem.nickname = $0.isEmpty ? nil : $0 }
        ))
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Helper Functions

    private func handleImageAction(_ actionArg: Any?) {
        guard let action = actionArg as? ImageEditorAction else { return }
        switch action {
        case .newImage(let image):
            viewModel.updatedItem.primaryImage = image
        case .deleteImage(let deletedImage):
            viewModel.updatedItem.primaryImage = deletedImage
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
