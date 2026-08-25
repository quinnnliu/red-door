//
//  CreateModelView-v2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import SwiftUI
import PhotosUI

// TODO: update this with actual fields

struct CreateItemsViewV2: View {
    // Environment variables
    @State private var viewModel: CreateItemsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isEditing: Bool = true

    init(template: ItemV2? = nil) {
        _viewModel = State(initialValue: CreateItemsViewModel(template: template))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar()
                
                ScrollView {
                    ItemImageEditor(
                        image: $viewModel.itemState.primaryImage
                    )

                    EditItemDetailSection(
                        description: $viewModel.itemState.description,
                        color: $viewModel.itemState.color,
                        material: $viewModel.itemState.material,
                        type: $viewModel.itemState.type,
                        essentialGroupId: $viewModel.itemState.essentialGroupId,
                        value: $viewModel.itemState.value,
                        brand: $viewModel.itemState.brand,
                        purchaseLocation: $viewModel.itemState.purchaseLocation,
                        datePurchased: $viewModel.itemState.datePurchased
                    )
                    .disabled(viewModel.templateState != nil)

                    ItemCountPicker
                }
                .ignoresSafeArea(.keyboard)
                
                Spacer()
                
                RDButton(
                    variant: .default,
                    size: .default,
                    leadingIcon: "plus",
                    label: "Add Items to Inventory"
                ) {
                    Task {
                        await viewModel.createItems()
                        dismiss()
                    }
                }
            }
            .toolbar(.hidden)
            .frameTop()
            .frameHorizontalPadding()
            
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Saving Model...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
            }
        }
        .overlay(
            ModelRDImageOverlay(selectedRDImage: viewModel.selectedRDImage, isImageSelected: $viewModel.isImageSelected)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isImageSelected)
        )
    }
    
    // MARK: - Top Bar
    
    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(
            leadingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: "xmark", iconBold: true, fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                VStack(alignment: .center, spacing: 6) {
                    ModelNameEntry
                    NicknameEntry
                }
            },
            trailingView: {
                Spacer().frame(24)
            }
        )
    }
    
    // MARK: Model Name Entry
    
    var ModelNameEntry: some View {
        TextField("Items Name", text: $viewModel.itemState.displayName)
            .padding(6)
            .background(viewModel.isImageSelected ? Color.clear : Color(.systemGray5))
            .cornerRadius(8)
            .multilineTextAlignment(.center)
            .disabled(viewModel.templateState != nil)
    }
    
    var NicknameEntry: some View {
        TextField("Nickname (optional)", text: nicknameBinding)
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .disabled(viewModel.templateState != nil)
    }
    
    // MARK: Item Count Picker
    
    private var ItemCountPicker: some View {
        Stepper("Number of Items: \(viewModel.itemCount)",
            value: $viewModel.itemCount,
            in: 1...1000
        )
    }
}

extension CreateItemsViewV2 {
    private var nicknameBinding: Binding<String> {
        Binding(
            get: { viewModel.itemState.nickname ?? "" },
            set: { viewModel.itemState.nickname = $0.isEmpty ? nil : $0 }
        )
    }
}

#Preview {
    CreateItemsViewV2()
}

