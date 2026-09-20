//
//  EditAccessoriesSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/20/26.
//

import SwiftUI

struct EditAccessoriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditAccessoriesViewModel

    private let accessoriesRepo: AccessoriesRepository
    private let originalTypeId: String
    private let onSave: (Accessories) -> Void

    @State private var editingAccessory: Accessories

    init(
        accessories: Accessories,
        viewModel: EditAccessoriesViewModel,
        accessoriesRepo: AccessoriesRepository,
        onSave: @escaping (Accessories) -> Void
    ) {
        self.originalTypeId = accessories.accessoriesTypeId
        self._editingAccessory = State(initialValue: accessories)
        self._viewModel = State(initialValue: viewModel)
        self.accessoriesRepo = accessoriesRepo
        self.onSave = onSave
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                DragIndicator()

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
                    leadingIcon: "checkmark",
                    iconBold: true,
                    label: "Save",
                    fullWidth: false
                ) {
                    saveAccessory()
                }
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
        .presentationDetents([.large])
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
                applyType(type)
                viewModel.showSelectTypeSheet = false
            }
        case let imageAction as ImageEditorAction:
            switch imageAction {
            case .newImage(let image):
                editingAccessory.primaryImage = image
            case .deleteImage(let image):
                editingAccessory.primaryImage = image
            }
        default:
            break
        }
    }

    private func applyType(_ type: AccessoriesType) {
        editingAccessory.accessoriesTypeId = type.id
        editingAccessory.baseName = type.displayName
        editingAccessory.baseNameLowercased = type.displayName.lowercased()
    }

    // MARK: - Save

    private func saveAccessory() {
        Task {
            viewModel.isLoading = true

            var accessoryToSave = editingAccessory

            if accessoryToSave.accessoriesTypeId != originalTypeId {
                let maxNumber = await accessoriesRepo.maxAccessoriesNumber(forTypeId: accessoryToSave.accessoriesTypeId)
                accessoryToSave.accessoriesNumber = maxNumber + 1
            }

            let imageNeedsUpdate = accessoryToSave.primaryImage.uiImage != nil
                || accessoryToSave.primaryImage.imageType == .delete
            if imageNeedsUpdate {
                accessoryToSave.primaryImage.documentId = accessoryToSave.id
                if let updatedImage = try? await FirebaseImageManager.shared.updateImage(
                    accessoryToSave.primaryImage,
                    resultImageType: .accessory
                ) {
                    accessoryToSave.primaryImage = updatedImage
                }
            }

            try? accessoriesRepo.set(document: accessoryToSave)

            viewModel.isLoading = false
            onSave(accessoryToSave)
            dismiss()
        }
    }
}

// MARK: - Top Bar

private extension EditAccessoriesSheet {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: "xmark", iconBold: true, fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                RDButton(
                    variant: .outline,
                    size: .default,
                    label: editingAccessory.baseName
                ) {
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

private extension EditAccessoriesSheet {
    var NicknameEntry: some View {
        TextField("Nickname (optional)", text: Binding(
            get: { editingAccessory.nickname ?? "" },
            set: { editingAccessory.nickname = $0.isEmpty ? nil : $0 }
        ))
        .font(.caption)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Select Accessories Type Sheet

private extension EditAccessoriesSheet {
    var SelectAccessoriesTypeSheet: some View {
        VStack {
            DragIndicator()

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
                        if let newType = viewModel.createAndSelectNewType() {
                            applyType(newType)
                        }
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

private extension EditAccessoriesSheet {
    var ImageSection: some View {
        PrimaryImageEditor(image: editingAccessory.primaryImage) { result in
            handleAction(result)
        }
    }
}

// MARK: - Description Section

private extension EditAccessoriesSheet {
    var DescriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .foregroundStyle(.red)

            TextField("Description", text: $editingAccessory.description, axis: .vertical)
                .lineLimit(3...6)
                .padding(10)
                .background(Color(.systemGray5))
                .cornerRadius(8)
        }
    }
}
