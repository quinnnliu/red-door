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
    
    init(viewModel: CreateItemsViewModel = CreateItemsViewModel()) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    TopBar()
                    
                    ModelImageView(
                        image: viewModel.modelState.image,
                        selectedImage: $viewModel.selectedRDImage,
                        isImageSelected: $viewModel.isImageSelected
                    )
                    
                    EditModelAttributesSection(
                        description: $viewModel.modelState.description,
                        color: $viewModel.modelState.color,
                        material: $viewModel.modelState.material,
                        type: $viewModel.modelState.type,
                        isEssential: $viewModel.modelState.isEssential,
                        value: $viewModel.modelState.value,
                        brand: $viewModel.modelState.brand,
                        purchaseLocation: $viewModel.modelState.purchaseLocation,
                        datePurchased: $viewModel.modelState.datePurchased
                    )
                    
                    Spacer()
                    
                    RDButton(variant: .default, size: .default, leadingIcon: "plus", text: "Add Model to Inventory") {
                        Task {
                            await viewModel.createModel()
                            dismiss()
                        }
                    }
                }
                .toolbar(.hidden)
                .frameTop()
                .frameHorizontalPadding()
            }
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
            leadingIcon: {
                RDButton(variant: .red, size: .icon, leadingIcon: "xmark", iconBold: true, fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                ModelNameEntry()
            },
            trailingIcon: {
                Spacer().frame(24)
            }
        )
    }
    
        // MARK: Model Name Entry
    
    @ViewBuilder
    private func ModelNameEntry() -> some View {
        TextField("Model Name", text: $viewModel.modelState.name)
            .padding(6)
            .background(viewModel.isImageSelected ? Color.clear : Color(.systemGray5))
            .cornerRadius(8)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    CreateModelViewV2()
}

