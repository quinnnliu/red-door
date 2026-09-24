//
//  EditItemSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/20/25.
//

import SwiftUI

struct EditItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var viewModel: ItemViewModel
    @State private var editingItem: Item
    @State private var isLoading: Bool = false
    
    @State private var showInvalidDeletionAlert: Bool = false
    let model: Model
    @FocusState private var focusAttentionReason: Bool

    init(viewModel: Binding<ItemViewModel>, model: Model) {
        _viewModel = viewModel
        self.editingItem = viewModel.wrappedValue.selectedItem
        self.model = model
    }

    // MARK: Body
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                TopBar()

                ItemImage(itemImage: $editingItem.image, isEditing: true)

                HStack(spacing: 0) {
                    Text("Item ID: ")
                        .font(.headline)
                        .foregroundColor(.red)

                    Text(editingItem.id)
                        .font(.caption)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Attention:", isOn: $editingItem.attention)
                        .toggleStyle(SwitchToggleStyle(tint: .red))
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)

                    if editingItem.attention {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Attention Reason: (optional)")
                                .font(.caption)
                                .foregroundColor(.red)

                            TextField("Reason", text: $editingItem.attentionReason)
                                .focused($focusAttentionReason)
                                .submitLabel(.done)
                                .onSubmit {
                                    focusAttentionReason = false
                                }
                                .padding(8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                RDButton(variant: .red, size: .default, leadingIcon: "trash", label: "Delete Item", fullWidth: false) {
                    if editingItem.isAvailable {
                        Task {
                            await viewModel.deleteItem()
                        }
                        dismiss()
                    } else {
                        showInvalidDeletionAlert = true
                    }
                }
            }
            .frameTop()
            .frameTopPadding()
            .frameHorizontalPadding()
            .toolbar(.hidden)
            .alert(
                "Cannot delete item that is currently installed",
                isPresented: $showInvalidDeletionAlert
            ) {
                Button("Cancel", role: .cancel) {
                    showInvalidDeletionAlert = false
                }
            }
            
            if isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Saving Item...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
            }
        }
    }

    // MARK: Top Bar
    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(leadingView: {
            RDButton(variant: .red, size: .icon, leadingIcon: "xmark", iconBold: true, fullWidth: false) {
                dismiss()
            }
            .clipShape(Circle())
        }, header: {
            HStack(spacing: 0) {
                Text("Editing: ")
                    .font(.headline)
                    .foregroundColor(.red)

                Text(model.name)
            }
        }, trailingView: {
            RDButton(variant: .red, size: .icon, leadingIcon: "checkmark", iconBold: true, fullWidth: false) {
                focusAttentionReason = false
                saveItem()
            }
            .clipShape(Circle())
        })
    }

    // MARK: Save Item
    private func saveItem() {
        if editingItem != viewModel.selectedItem {
            Task {
                isLoading = true
                if !editingItem.attention {
                    editingItem.attentionReason = ""
                }
                viewModel.selectedItem = editingItem
                await viewModel.updateItem()
                isLoading = false
                dismiss()
            }
        }
    }
}
