//
//  EditItemSheetV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import SwiftUI

struct EditItemSheetV2: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator.self) private var coordinator: NavigationCoordinator

    var viewModel: ItemDetailViewModel
    @State private var editingItem: ItemV2
    var onDelete: (() -> Void)?

    // Loading and delete
    @State private var showDeleteAlert: Bool = false
    @State private var selectedGroup: EssentialsGroup? = nil

    init(viewModel: ItemDetailViewModel, onDelete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.editingItem = viewModel.itemState
        self.onDelete = onDelete
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    TopBar()

                    PrimaryImageEditor(image: editingItem.primaryImage) { action in
                        handleImageAction(action)
                    }

                    EditItemDetailSection(
                        description: $editingItem.description,
                        color: $editingItem.color,
                        material: $editingItem.material,
                        type: $editingItem.type,
                        selectedGroup: $selectedGroup,
                        groups: viewModel.availableGroups,
                        value: $editingItem.value,
                        brand: $editingItem.brand,
                        purchaseLocation: $editingItem.purchaseLocation,
                        datePurchased: $editingItem.datePurchased
                    )

                    Spacer()

                    RDButton(variant: .red, size: .default, leadingIcon: "trash", label: "Delete Item", fullWidth: false) {
                        showDeleteAlert = true
                    }
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
            if let groupId = editingItem.essentialGroupId {
                selectedGroup = viewModel.availableGroups.first { $0.id == groupId }
            }
        }
    }

    // MARK: - Top Bar

    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(
            leadingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.xmark, fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                VStack(alignment: .center, spacing: 6) {
                    ItemNameEntry
                    NicknameEntry
                }
            },
            trailingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: "checkmark", fullWidth: false) {
                    saveItem()
                }
                .clipShape(Circle())
            }
        )
    }

    // MARK: - Item Name Entry

    var ItemNameEntry: some View {
        TextField("Item Name", text: $editingItem.baseName)
            .padding(6)
            .background(Color(.systemGray5))
            .cornerRadius(8)
            .multilineTextAlignment(.center)
    }
    
    var NicknameEntry: some View {
        TextField("Nickname (optional)", text: Binding(
            get: { editingItem.nickname ?? "" },
            set: { editingItem.nickname = $0.isEmpty ? nil : $0 }
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
            editingItem.primaryImage = image
        case .deleteImage(let deletedImage):
            editingItem.primaryImage = deletedImage
        }
    }

    private func saveItem() {
        Task {
            let oldGroupId = editingItem.essentialGroupId
            editingItem.essentialGroupId = selectedGroup?.id
            viewModel.itemState = editingItem
            await viewModel.updateItem(oldGroupId: oldGroupId)
            dismiss()
        }
    }

    private func deleteItem() {
        Task {
            await viewModel.deleteItem()
            onDelete?()
            coordinator.resetSelectedPath()
        }
    }
}
