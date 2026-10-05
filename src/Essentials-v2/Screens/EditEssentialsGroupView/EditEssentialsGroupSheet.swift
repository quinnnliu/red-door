//
//  EditEssentialsGroupSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/12/26.
//

import SwiftUI

struct EditEssentialsGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EditEssentialsGroupViewModel

    private let essentialsRepo: EssentialsRepository
    private let originalTypeId: String
    private let onDelete: () -> Void

    @State private var editingGroup: EssentialsGroup
    private var originalGroup: EssentialsGroup

    init(
        group: EssentialsGroup,
        viewModel: EditEssentialsGroupViewModel,
        essentialsRepo: EssentialsRepository,
        onDelete: @escaping () -> Void = {}
    ) {
        self.onDelete = onDelete
        self.originalGroup = group
        self.originalTypeId = group.essentialsTypeId
        self._editingGroup = State(initialValue: group)
        self._viewModel = State(initialValue: viewModel)
        self.essentialsRepo = essentialsRepo
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                DragIndicator()
                
                VStack(alignment: .center, spacing: 6) {
                    TopBar
                    NicknameEntry
                }
                
                GroupTypeSection

                Spacer()
                
                HStack(spacing: 12) {
                    RDButton(
                        style: .default,
                        size: .default,
                        leadingIcon: "trash",
                        label: "Delete",
                        fullWidth: false
                    ) {
                        deleteGroup()
                    }
                    .disabled(!originalGroup.itemIds.isEmpty)

                    RDButton(
                        style: .red,
                        size: .default,
                        leadingIcon: "checkmark",
                        label: "Save",
                        fullWidth: false
                    ) {
                        saveGroup()
                    }
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
        .presentationDetents([.medium])
        .sheet(isPresented: $viewModel.showGroupTypePicker) {
            SelectDocumentSheet(
                title: "Select Group Type",
                documents: viewModel.groupTypes,
                action: handleAction(_:)
            )
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
                applyGroupType(type)
            default:
                break
            }
        default:
            break
        }
    }

    private func applyGroupType(_ type: EssentialsGroupType) {
        editingGroup.essentialsTypeId = type.id
        editingGroup.baseName = type.displayName
        editingGroup.baseNameLowercased = type.displayName.lowercased()
        editingGroup.emoji = type.emoji
    }

    // MARK: - Top Bar
    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                Spacer().frame(24)
            },
            header: {
                Text("Editing Essentials Group")
                    .bold()
                    .foregroundStyle(.red)
            },
            trailingView: {
                Spacer().frame(24)
            }
        )
    }

    // MARK: - Nickname Entry

    var NicknameEntry: some View {
        TextField("Nickname (optional)", text: Binding(
            get: { editingGroup.nickname ?? "" },
            set: { editingGroup.nickname = $0.isEmpty ? nil : $0 }
        ))
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Delete

    private func deleteGroup() {
        guard originalGroup.itemIds.isEmpty else { return }
        Task {
            viewModel.isLoading = true
            do {
                try await essentialsRepo.delete(id: editingGroup.id)
                viewModel.isLoading = false
                dismiss()
                onDelete()
            } catch {
                viewModel.isLoading = false
                print("Error deleting essentials group: \(error)")
            }
        }
    }

    // MARK: - Save

    private func saveGroup() {
        Task {
            viewModel.isLoading = true

            if editingGroup.essentialsTypeId != originalTypeId {
                let maxNumber = await essentialsRepo.maxGroupNumber(forTypeId: editingGroup.essentialsTypeId)
                editingGroup.groupNumber = maxNumber + 1
            }

            let fields: [String: AnyHashable] = [
                EssentialsGroup.CodingKeys.essentialsTypeId.stringValue: editingGroup.essentialsTypeId,
                EssentialsGroup.CodingKeys.baseName.stringValue: editingGroup.baseName,
                EssentialsGroup.CodingKeys.baseNameLowercased.stringValue: editingGroup.baseNameLowercased,
                EssentialsGroup.CodingKeys.groupNumber.stringValue: editingGroup.groupNumber,
                EssentialsGroup.CodingKeys.nickname.stringValue: editingGroup.nickname ?? nil,
                EssentialsGroup.CodingKeys.emoji.stringValue: editingGroup.emoji
            ]

            try? await essentialsRepo.update(id: editingGroup.id, fields: fields)
            viewModel.isLoading = false
            dismiss()
        }
    }
}

// MARK: - Group Type Section

private extension EditEssentialsGroupSheet {
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
                    TextField("Emoji (default ⭐️)", text: $viewModel.newGroupTypeEmoji)
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                        .padding(10)
                        .background(Color(.systemGray5))
                        .cornerRadius(Constants.CornerRadius.medium)

                    TextField("New type name", text: $viewModel.newGroupTypeName)
                        .padding(10)
                        .background(Color(.systemGray5))
                        .cornerRadius(Constants.CornerRadius.medium)

                    RDButton(style: .default, size: .sm, label: "Create", fullWidth: false) {
                        withAnimation(Constants.Animation.snappy) {
                            if let newType = viewModel.createAndSelectNewGroupType() {
                                applyGroupType(newType)
                            }
                        }
                    }
                    .disabled(!viewModel.newGroupTypeValid)
                }
            }

            HStack {
                Text("\(viewModel.groupTypes.first(where: { $0.id == editingGroup.essentialsTypeId })?.emoji ?? "⭐️") \(editingGroup.baseName)")
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
        }
    }
}
