//
//  CreateEssentialsGroupView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import SwiftUI

struct CreateEssentialsGroupView: View {
    @State private var viewModel: CreateEssentialsGroupViewModel = CreateEssentialsGroupViewModel()
    @Environment(\.dismiss) var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar

                ScrollView {
                    VStack(spacing: 16) {
                        GroupTypeSection
                        SelectedItemsSection
                        SelectedAccessoriesSection

                        RDButton(
                            variant: .default,
                            size: .default,
                            leadingIcon: "plus",
                            label: "Create Essentials Group",
                            fullWidth: true
                        ) {
                            Task {
                                let success = await viewModel.createEssentialsGroup()
                                if success { dismiss() }
                            }
                        }
                        .disabled(viewModel.selectedGroupType == nil)
                    }
                    .padding(.top, 4)
                }
                .ignoresSafeArea(.keyboard)
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
        .sheet(isPresented: $viewModel.showGroupTypePicker) {
            SelectDocumentSheet(
                title: "Select Group Type",
                documents: viewModel.groupTypes,
                action: handleAction(_:)
            )
        }
        .sheet(isPresented: $viewModel.showItemPickerSheet) {
            ItemPickerSheet(selectedIds: viewModel.selectedItemIds) { item in
                viewModel.addItem(item)
            }
        }
        .sheet(isPresented: $viewModel.showAddAccessoriesSheet) {
            // TODO: AddAccessoriesToEssentialsSheet
        }
        .task {
            await viewModel.loadGroupTypes()
        }
    }

    // MARK: - Action Handling

    private func handleAction(_ action: Any?) {
        guard let action else { return }
        switch action {
        case let sheetAction as SelectDocumentSheetAction<EssentialsGroupType>:
            switch sheetAction {
            case .selected(let type):
                viewModel.selectedGroupType = type
            }
        default:
            break
        }
    }
}

// MARK: - Top Bar

private extension CreateEssentialsGroupView {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: "xmark", iconBold: true, fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                Text(viewModel.selectedGroupType?.displayName ?? "New Essentials Group")
                    .font(.headline)
            },
            trailingView: {
                Spacer().frame(width: 44)
            }
        )
    }
}

// MARK: - Group Type Section

private extension CreateEssentialsGroupView {
    var GroupTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Group Type")
                .foregroundStyle(.red)

            if let selected = viewModel.selectedGroupType {
                HStack {
                    Text(selected.displayName)
                        .font(.body)
                        .bold()
                    Spacer()
                    RDButton(variant: .outline, size: .sm, label: "Change", fullWidth: false) {
                        viewModel.showGroupTypePicker = true
                    }
                }
                .padding(12)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            } else {
                RDButton(variant: .outline, size: .default, label: "Select Type", fullWidth: true) {
                    viewModel.showGroupTypePicker = true
                }
            }

            if viewModel.showNewTypeField {
                HStack(spacing: 8) {
                    TextField("New type name", text: $viewModel.newGroupTypeName)
                        .padding(10)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)

                    RDButton(variant: .default, size: .sm, label: "Create", fullWidth: false) {
                        Task { await viewModel.createAndSelectNewGroupType() }
                    }
                    .disabled(viewModel.newGroupTypeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.showNewTypeField.toggle()
                    if !viewModel.showNewTypeField { viewModel.newGroupTypeName = "" }
                }
            } label: {
                Label(
                    viewModel.showNewTypeField ? "Cancel" : "New Type",
                    systemImage: viewModel.showNewTypeField ? "xmark" : "plus"
                )
                .font(.subheadline)
                .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Selected Items Section

private extension CreateEssentialsGroupView {
    var SelectedItemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Items")
                    .foregroundStyle(.red)
                Spacer()
                Text("\(viewModel.selectedItemIds.count) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.selectedItems.isEmpty {
                VStack(spacing: 4) {
                    ForEach(viewModel.selectedItems, id: \.id) { item in
                        HStack {
                            Text(item.displayName)
                                .font(.body)
                            Spacer()
                            Button {
                                viewModel.removeItem(item)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                    }
                }
            }

            RDButton(variant: .outline, size: .default, leadingIcon: "plus", label: "Add Items", fullWidth: true) {
                viewModel.showItemPickerSheet = true
            }
        }
    }
}

// MARK: - Selected Accessories Section

private extension CreateEssentialsGroupView {
    var SelectedAccessoriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accessories")
                .foregroundStyle(.red)

            if let accessory = viewModel.selectedAccessory {
                HStack {
                    Text(accessory.displayName)
                        .font(.body)
                    Spacer()
                    Button {
                        viewModel.clearAccessory()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            } else {
                RDButton(variant: .outline, size: .default, leadingIcon: "plus", label: "Add Accessories", fullWidth: true) {
                    viewModel.showAccessoriesPickerSheet = true
                }
            }
        }
    }
}

#Preview {
    CreateEssentialsGroupView()
}
