//
//  CreateEssentialsGroupView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import SwiftUI

struct CreateEssentialsGroupView: View {
    @State private var viewModel: CreateEssentialsGroupViewModel
    @Environment(\.dismiss) var dismiss

    init(viewModel: CreateEssentialsGroupViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar

                ScrollView {
                    VStack(spacing: 16) {
                        GroupTypeSection
                        SelectedAccessoriesSection
                        StorageLocationRow
                    }
                    .padding(.horizontal, 8)
                }
                .ignoresSafeArea(.keyboard)
                
                Spacer()
                
                RDButton(
                    style: .red,
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
                .disabled(viewModel.selectedGroupType == nil || viewModel.selectedStorageLocation == nil)
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
                refreshAction: { Task { await viewModel.refreshGroupTypes() } },
                action: handleAction(_:)
            )
        }
        .sheet(isPresented: $viewModel.showAddAccessoriesSheet) {
            SelectAccessoriesSheet(action: handleAction(_:))
        }
        .alert(
            viewModel.existingTypeMatchingNewName == nil ? "Create New Group Type?" : "Type Already Exists",
            isPresented: $viewModel.showConfirmNewTypeAlert
        ) {
            if viewModel.existingTypeMatchingNewName != nil {
                Button("Use Existing") {
                    withAnimation(Constants.Animation.snappy) {
                        viewModel.selectExistingTypeMatchingNewName()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } else {
                Button("Create") {
                    withAnimation(Constants.Animation.snappy) {
                        viewModel.createAndSelectNewGroupType()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        } message: {
            if let existing = viewModel.existingTypeMatchingNewName {
                Text("\"\(existing.emoji) \(existing.displayName)\" is already in the list of group types. Use it instead of creating a duplicate?")
            } else {
                Text("\"\(viewModel.newGroupTypeName.trimmingCharacters(in: .whitespacesAndNewlines))\" doesn't exist in the current group types. This will create a brand new group type.")
            }
        }
        .task {
            await viewModel.loadGroupTypes()
            await viewModel.loadStorageLocations()
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
            default:
                break
            }
        case let accessoriesAction as AccessoriesListItemAction:
            switch accessoriesAction {
            case .select(let accessories):
                viewModel.selectAccessory(accessories)
            default:
                break
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
                RDButton(style: .red, size: .icon, leadingIcon: "xmark", fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                VStack(alignment: .center, spacing: 6) {
                    Text(viewModel.selectedGroupType?.displayName ?? "New Essentials Group")
                        .font(.headline)
                    NicknameEntry
                }
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
            HStack {
                Text("Group Type")
                    .foregroundStyle(.red)

                Spacer()

                Button {
                    withAnimation(Constants.Animation.snappy) {
                        viewModel.showNewTypeField.toggle()
                        if !viewModel.showNewTypeField { viewModel.newGroupTypeName = "" }
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
                    VStack(spacing: 4) {
                        Text("Emoji (default ⭐️)")
                            .font(.caption)
                        TextField("", text: $viewModel.newGroupTypeEmoji)
                            .multilineTextAlignment(.center)
                            .padding(8)
                            .background(Color(.systemGray5))
                            .cornerRadius(Constants.CornerRadius.medium)
                            .font(.caption2)
                    }
                    
                    VStack(spacing: 4) {
                        Text("New Type Name")
                            .font(.caption)
                        TextField("Enter Name", text: $viewModel.newGroupTypeName)
                            .padding(8)
                            .background(Color(.systemGray5))
                            .cornerRadius(Constants.CornerRadius.medium)
                            .font(.caption)
                    }

                    RDButton(style: .default, size: .sm, label: "Create", fullWidth: false) {
                        viewModel.showConfirmNewTypeAlert = true
                    }
                    .disabled(!viewModel.newGroupTypeValid)
                }
            }

            if let selected = viewModel.selectedGroupType, !viewModel.showNewTypeField {
                HStack {
                    Text("\(selected.emoji) \(selected.displayName)")
                        .font(.body)
                        .bold()
                    Spacer()
                    RDButton(style: .outline, size: .sm, label: "Change", fullWidth: false) {
                        viewModel.showGroupTypePicker = true
                    }
                }
                .padding(12)
                .background(Color(.systemGray5))
                .cornerRadius(Constants.CornerRadius.medium)
            } else {
                RDButton(style: .outline, size: .default, label: "Select Type", fullWidth: true) {
                    viewModel.showGroupTypePicker = true
                }
            }
        }
    }
}

// MARK: - Nickname Entry

private extension CreateEssentialsGroupView {
    var NicknameEntry: some View {
        TextField("Nickname (optional)", text: $viewModel.nickname)
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Storage Location Row

private extension CreateEssentialsGroupView {
    var StorageLocationRow: some View {
        StorageLocationPicker(
            locations: viewModel.storageLocations,
            selected: $viewModel.selectedStorageLocation,
            refreshAction: { Task { await viewModel.refreshStorageLocations() } }
        )
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
                .cornerRadius(Constants.CornerRadius.medium)
            } else {
                RDButton(style: .outline, size: .default, leadingIcon: "plus", label: "Add Accessories", fullWidth: true) {
                    viewModel.showAddAccessoriesSheet = true
                }
            }
        }
    }
}
