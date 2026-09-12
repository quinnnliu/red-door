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
                    }
                    .padding(.horizontal, 8)
                }
                .ignoresSafeArea(.keyboard)
                
                Spacer()
                
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
                action: handleAction(_:),
                refreshAction: { Task { await viewModel.refreshGroupTypes() } }
            )
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
                    withAnimation(.easeInOut(duration: 0.2)) {
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
                    TextField("Emoji (default ⭐️)", text: $viewModel.newGroupTypeEmoji)
                        .multilineTextAlignment(.center)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .font(.caption)

                    TextField("New type name", text: $viewModel.newGroupTypeName)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .font(.caption)

                    RDButton(variant: .default, size: .sm, label: "Create", fullWidth: false) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.createAndSelectNewGroupType()
                        }
                    }
                    .disabled(!viewModel.newGroupTypeValid)
                }
            }

            if let selected = viewModel.selectedGroupType {
                HStack {
                    Text("\(selected.emoji) \(selected.displayName)")
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
                    viewModel.showAddAccessoriesSheet = true
                }
            }
        }
    }
}
