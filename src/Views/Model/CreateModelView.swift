//
//  CreateModelView.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/22/24.
//

import PhotosUI
import SwiftUI

struct CreateModelView: View {
    // Environment variables
    @State private var viewModel: ModelViewModel = .init() // initializes new blank model
    @Environment(\.dismiss) var dismiss
    @State private var isEditing: Bool = true

    // Image Overlay
    @State private var selectedRDImage: RDImage? = nil
    @State private var isImageSelected: Bool = false

    // Loading Variables
    @State private var isLoading: Bool = false

    init(viewModel: ModelViewModel = ModelViewModel()) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 12) {
                    TopBar()

                    ModelImages(model: $viewModel.selectedModel, selectedRDImage: $selectedRDImage, isImageSelected: $isImageSelected, isEditing: $isEditing)

                    EditModelInformationSection(viewModel: $viewModel)

                    Spacer()

                    RDButton(variant: .default, size: .default, leadingIcon: "plus", label: "Add Model to Inventory") {
                        saveModel()
                    }
                }   
                .toolbar(.hidden)
                .frameTop()
                .frameHorizontalPadding()

                if isLoading {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("Saving Model...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                        .shadow(radius: 10)
                }
            }
        }
        .overlay(
            ModelRDImageOverlay(selectedRDImage: selectedRDImage, isImageSelected: $isImageSelected)
                .animation(.easeInOut(duration: 0.3), value: isImageSelected)
        )
    }

    // MARK: saveModel()

    private func saveModel() {
        isLoading = true
        Task {
            await viewModel.updateModel()
            isLoading = false
            dismiss()
        }
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
        TextField("Model Name", text: $viewModel.selectedModel.name)
            .padding(6)
            .background(isImageSelected ? Color.clear : Color(.systemGray5))
            .cornerRadius(8)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    CreateModelView()
}
