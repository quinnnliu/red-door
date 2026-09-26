//
//  CreateAccessoriesView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import SwiftUI

struct CreateAccessoriesView: View {
    @State private var viewModel: CreateAccessoriesViewModel
    @Environment(\.dismiss) var dismiss    

    init(viewModel: CreateAccessoriesViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                VStack(spacing: 6) {
                    TopBar
                    
                    NicknameEntry
                }
                
                ImageSection

                DescriptionSection
                
                Spacer()

                RDButton(
                    variant: .red,
                    size: .default,
                    leadingIcon: "plus",
                    label: "Add Accessory",
                    fullWidth: true
                ) {
                    Task {
                        let success = await viewModel.createAccessories()
                        if success { dismiss() }
                    }
                }
                .disabled(viewModel.selectedType == nil)
            }
            .toolbar(.hidden)
            .frameTop()
            .frameHorizontalPadding()

            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Saving...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
            }
        }
        .sheet(isPresented: $viewModel.showSelectTypeSheet) {
            SelectAccessoriesTypeSheet
        }
        .task {
            await viewModel.loadTypes()
        }
    }

    // MARK: - Action Handling

    private func handleAction(_ action: Any?) {
        guard let action else { return }
        switch action {
        case let sheetAction as SelectDocumentSheetAction<AccessoriesType>:
            switch sheetAction {
            case .selected(let type):
                viewModel.selectedType = type
                viewModel.showSelectTypeSheet = false
            }
        case let imageAction as ImageEditorAction:
            switch imageAction {
            case .newImage(let image):
                viewModel.primaryImage = image
            case .deleteImage:
                viewModel.primaryImage = nil
            }

        default:
            break
        }
    }
}

// MARK: - Top Bar

private extension CreateAccessoriesView {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: "xmark", fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                RDButton(
                    variant: .outline,
                    size: .default,
                    label: viewModel.selectedType?.displayName ?? "Accessory Type") {
                        viewModel.showSelectTypeSheet = true
                }
            },
            trailingView: {
                Spacer().frame(width: 44)
            }
        )
    }
}

// MARK: - Nickname Entry

private extension CreateAccessoriesView {
    var NicknameEntry: some View {
        TextField("Nickname (optional)", text: $viewModel.nickname)
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
    }
}

// MARK: Select Accessories Type Sheet
private extension CreateAccessoriesView {
    var SelectAccessoriesTypeSheet: some View {
        VStack {
            DragIndicator()
            
            Spacer(minLength: .zero)
            
            Text("Select Accessories Type")
                .bold()
                .foregroundStyle(.red)
            
            VStack {
                Text("Create New Type")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 8) {
                    TextField("New type name", text: $viewModel.newTypeName)
                        .font(.caption)
                        .padding(10)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)

                    RDButton(variant: .default, size: .default, label: "Create", fullWidth: false) {
                        viewModel.createAndSelectNewType()
                    }
                    .disabled(viewModel.newTypeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            VStack {
                Text("Select Existing Type")
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                RDButton(variant: .outline, size: .default, label: "Select Type", fullWidth: true) {
                    viewModel.showExistingTypePicker = true
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
        }
        .frameHorizontalPadding()
        .presentationDetents([.fraction(0.4)])
        .sheet(isPresented: $viewModel.showExistingTypePicker) {
            SelectDocumentSheet(
                title: "Select Accessories Type",
                documents: viewModel.accessoriesTypes,
                action: handleAction(_:),
                refreshAction: { Task { await viewModel.refreshTypes() } }
            )
        }
    }
}

// MARK: - Image Section

private extension CreateAccessoriesView {
    var ImageSection: some View {
        PrimaryImageEditor(image: viewModel.primaryImage) { result in
            handleAction(result)
        }
    }
}

// MARK: - Description Section

private extension CreateAccessoriesView {
    var DescriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .foregroundStyle(.red)

            TextField("Description", text: $viewModel.description, axis: .vertical)
                .lineLimit(3...6)
                .padding(10)
                .background(Color(.systemGray5))
                .cornerRadius(8)
        }
    }
}
