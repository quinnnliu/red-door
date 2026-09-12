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
        _viewModel = State(initialValue: viewModel)
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
                
                AccessoriesTypeSection

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
        .sheet(isPresented: $viewModel.showTypePicker) {
            SelectDocumentSheet(
                title: "Select Accessories Type",
                documents: viewModel.accessoriesTypes,
                action: handleAction(_:),
                refreshAction: { Task { await viewModel.refreshTypes() } }
            )
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
                RDButton(variant: .red, size: .icon, leadingIcon: "xmark", iconBold: true, fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                Text(viewModel.selectedType?.displayName ?? "Accessory Name")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .foregroundStyle(viewModel.selectedType == nil ? Color(.systemGray) : .black)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    .multilineTextAlignment(.center)
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

// MARK: - Accessories Type Section

private extension CreateAccessoriesView {
    var AccessoriesTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Accessories Type")
                    .foregroundStyle(.red)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.showNewTypeField.toggle()
                        if !viewModel.showNewTypeField { viewModel.newTypeName = "" }
                    }
                } label: {
                    Label(
                        viewModel.showNewTypeField ? "Cancel" : "New Type",
                        systemImage: viewModel.showNewTypeField ? SFSymbols.xmark : SFSymbols.plus
                    )
                    .font(.subheadline)
                    .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }

            if viewModel.showNewTypeField {
                HStack(spacing: 8) {
                    TextField("New type name", text: $viewModel.newTypeName)
                        .padding(10)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)

                    RDButton(variant: .default, size: .sm, label: "Create", fullWidth: false) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.createAndSelectNewType()
                        }
                    }
                    .disabled(viewModel.newTypeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if let selected = viewModel.selectedType {
                HStack {
                    Text(selected.displayName)
                        .font(.body)
                        .bold()
                    Spacer()
                    RDButton(variant: .outline, size: .sm, label: "Change", fullWidth: false) {
                        viewModel.showTypePicker = true
                    }
                }
                .padding(12)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            } else {
                RDButton(variant: .outline, size: .default, label: "Select Type", fullWidth: true) {
                    viewModel.showTypePicker = true
                }
            }
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
