//
//  EditItemSheetV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import SwiftUI

struct EditItemSheetV2: View {
    @Environment(\.dismiss) private var dismiss

    var viewModel: ItemDetailViewModel
    @State private var editingItem: ItemV2
    var onDelete: (() -> Void)?

    // Image overlay
    @State private var selectedRDImage: RDImage? = nil
    @State private var isImageSelected: Bool = false

    // Loading and delete
    @State private var showDeleteAlert: Bool = false

    init(viewModel: ItemDetailViewModel, onDelete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.editingItem = viewModel.item
        self.onDelete = onDelete
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    TopBar()

                    ItemImageEditor(image: $editingItem.primaryImage)

                    EditItemDetailSection(
                        description: $editingItem.description,
                        color: $editingItem.color,
                        material: $editingItem.material,
                        type: $editingItem.type,
                        essentialGroupId: $editingItem.essentialGroupId,
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
            .overlay(
                ModelRDImageOverlay(selectedRDImage: selectedRDImage, isImageSelected: $isImageSelected)
                    .animation(.easeInOut(duration: 0.3), value: isImageSelected)
            )

            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Saving Item...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
            }
        }
    }

    // MARK: - Top Bar

    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(
            leadingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.xmark, iconBold: true, fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                ItemNameEntry()
            },
            trailingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: "checkmark", iconBold: true, fullWidth: false) {
                    saveItem()
                }
                .clipShape(Circle())
            }
        )
    }

    // MARK: - Item Name Entry

    @ViewBuilder
    private func ItemNameEntry() -> some View {
        TextField("Item Name", text: $editingItem.displayName)
            .padding(6)
            .background(isImageSelected ? Color.clear : Color(.systemGray5))
            .cornerRadius(8)
            .multilineTextAlignment(.center)
    }

    // MARK: - Helper Functions

    private func saveItem() {
        Task {
            viewModel.item = editingItem
            await viewModel.updateItem()
            dismiss()
        }
    }

    private func deleteItem() {
        Task {
            await viewModel.deleteItem()
            onDelete?()
            dismiss()
        }
    }
}
