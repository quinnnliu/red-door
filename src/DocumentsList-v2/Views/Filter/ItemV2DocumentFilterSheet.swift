//
//  ItemV2DocumentFilterSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/22/26.
//

import SwiftUI

struct ItemV2DocumentFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    var action: (Any?) -> Void

    // MARK: - Filter State

    @State private var selectedType: ItemType?
    @State private var selectedColor: ItemColor?
    @State private var selectedMaterial: ItemMaterial?
    @State private var selectedStatus: LocationStatus?
    @State private var selectedAttention: Bool?
    @State private var selectedGroup: EssentialsGroup?

    // MARK: - Data

    let availableGroups: [EssentialsGroup]
    private let lockedFilterKeys: Set<String>

    // MARK: - Filter Keys

    private static let typeKey      = ItemV2.CodingKeys.type.stringValue
    private static let colorKey     = ItemV2.CodingKeys.color.stringValue
    private static let materialKey  = ItemV2.CodingKeys.material.stringValue
    private static let statusKey    = "\(ItemV2.CodingKeys.location.stringValue).\(DocumentLocation.CodingKeys.status.stringValue)"
    private static let attentionKey = ItemV2.CodingKeys.attention.stringValue
    private static let groupKey     = ItemV2.CodingKeys.essentialGroupId.stringValue

    // MARK: - Init

    init(
        action: @escaping (Any?) -> Void,
        initialFilters: [String: AnyHashable] = [:],
        availableGroups: [EssentialsGroup] = [],
        lockedFilterKeys: Set<String> = []
    ) {
        self.action = action
        self.availableGroups = availableGroups
        self.lockedFilterKeys = lockedFilterKeys
        _selectedType      = State(initialValue: (initialFilters[Self.typeKey] as? String).flatMap(ItemType.init(rawValue:)))
        _selectedColor     = State(initialValue: (initialFilters[Self.colorKey] as? String).flatMap(ItemColor.init(rawValue:)))
        _selectedMaterial  = State(initialValue: (initialFilters[Self.materialKey] as? String).flatMap(ItemMaterial.init(rawValue:)))
        _selectedStatus    = State(initialValue: (initialFilters[Self.statusKey] as? String).flatMap(LocationStatus.init(rawValue:)))
        _selectedAttention = State(initialValue: initialFilters[Self.attentionKey] as? Bool)
        let groupId = initialFilters[Self.groupKey] as? String
        _selectedGroup     = State(initialValue: availableGroups.first { $0.id == groupId })
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            DragIndicator()
                .padding(.top, 8)

            TopBar

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if lockedFilterKeys.contains(Self.typeKey) {
                        LockedFilterRow(title: "Type", value: selectedType?.title ?? "Any")
                    } else {
                        FilterPickerRow(selectedItem: $selectedType, items: ItemType.allCases, title: "Type")
                    }

                    if lockedFilterKeys.contains(Self.statusKey) {
                        LockedFilterRow(title: "Status", value: selectedStatus?.title ?? "Any")
                    } else {
                        FilterPickerRow(selectedItem: $selectedStatus, items: LocationStatus.allCases, title: "Status")
                    }

                    if lockedFilterKeys.contains(Self.colorKey) {
                        LockedFilterRow(title: "Color", value: selectedColor?.title ?? "Any")
                    } else {
                        FilterPickerRow(selectedItem: $selectedColor, items: ItemColor.allCases, title: "Color")
                    }

                    if lockedFilterKeys.contains(Self.materialKey) {
                        LockedFilterRow(title: "Material", value: selectedMaterial?.title ?? "Any")
                    } else {
                        FilterPickerRow(selectedItem: $selectedMaterial, items: ItemMaterial.allCases, title: "Material")
                    }

                    if lockedFilterKeys.contains(Self.attentionKey) {
                        LockedFilterRow(title: "Attention", value: selectedAttention != nil ? "Yes" : "Any")
                    } else {
                        AttentionRow
                    }

                    if !availableGroups.isEmpty {
                        if lockedFilterKeys.contains(Self.groupKey) {
                            LockedFilterRow(title: "Essentials Group", value: selectedGroup?.displayName ?? "Any")
                        } else {
                            EssentialsGroupRow
                        }
                    }
                }
            }

            ApplyButton
                .padding(.top, 12)
        }
        .frameTop()
        .frameHorizontalPadding()
    }
}

// MARK: - Subviews

private extension ItemV2DocumentFilterSheet {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton(icon: SFSymbols.xmark)
            },
            header: {
                Text("Filter Items")
                    .font(.headline)
                    .foregroundStyle(.red)
            },
            trailingView: {
                SmallCTA(
                    type: hasActiveFilters ? .red : .secondary,
                    text: "Reset"
                ) {
                    resetFilters()
                }
                .disabled(!hasActiveFilters)
            }
        )
    }

    var AttentionRow: some View {
        HStack {
            Text("Attention")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Spacer()
            Button {
                withAnimation(.snappy) {
                    selectedAttention = selectedAttention == nil ? true : nil
                }
            } label: {
                Text(selectedAttention != nil ? "Yes" : "No")
                    .font(.subheadline)
                    .foregroundStyle(selectedAttention != nil ? .red : .secondary)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(selectedAttention != nil ? Color.red.opacity(0.1) : Color(.systemGray5))
                    )
                    .overlay(
                        Capsule()
                            .stroke(selectedAttention != nil ? Color.red.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    var EssentialsGroupRow: some View {
        HStack {
            Text("Essentials Group")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Spacer()
            Picker("", selection: $selectedGroup) {
                Text("Any").tag(Optional<EssentialsGroup>.none)
                ForEach(availableGroups) { group in
                    Text(group.displayName).tag(Optional(group))
                }
            }
            .pickerStyle(.menu)
            .tint(selectedGroup != nil ? .red : .secondary)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    var ApplyButton: some View {
        RDButton(variant: .red, label: "Apply Filters", fullWidth: true) {
            applyFilters()
        }
    }
}

// MARK: - LockedFilterRow

private struct LockedFilterRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Image(systemName: SFSymbols.lockFill)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) { Divider() }
    }
}

// MARK: - Actions

private extension ItemV2DocumentFilterSheet {

    var hasActiveFilters: Bool {
        (selectedType != nil     && !lockedFilterKeys.contains(Self.typeKey))
        || (selectedColor != nil    && !lockedFilterKeys.contains(Self.colorKey))
        || (selectedMaterial != nil && !lockedFilterKeys.contains(Self.materialKey))
        || (selectedStatus != nil   && !lockedFilterKeys.contains(Self.statusKey))
        || (selectedAttention != nil && !lockedFilterKeys.contains(Self.attentionKey))
        || (selectedGroup != nil    && !lockedFilterKeys.contains(Self.groupKey))
    }

    func buildFilterDictionary() -> [String: AnyHashable] {
        var filters: [String: AnyHashable] = [:]
        if let type = selectedType,     !lockedFilterKeys.contains(Self.typeKey)      { filters[Self.typeKey] = type.rawValue }
        if let color = selectedColor,   !lockedFilterKeys.contains(Self.colorKey)     { filters[Self.colorKey] = color.rawValue }
        if let mat = selectedMaterial,  !lockedFilterKeys.contains(Self.materialKey)  { filters[Self.materialKey] = mat.rawValue }
        if let status = selectedStatus, !lockedFilterKeys.contains(Self.statusKey)    { filters[Self.statusKey] = status.rawValue }
        if let attention = selectedAttention, !lockedFilterKeys.contains(Self.attentionKey) { filters[Self.attentionKey] = attention }
        if let group = selectedGroup,   !lockedFilterKeys.contains(Self.groupKey)     { filters[Self.groupKey] = group.id }
        return filters
    }

    func applyFilters() {
        action(DocumentFilterSheetAction.applyFilters(buildFilterDictionary()))
        dismiss()
    }

    func resetFilters() {
        if !lockedFilterKeys.contains(Self.typeKey)      { selectedType = nil }
        if !lockedFilterKeys.contains(Self.colorKey)     { selectedColor = nil }
        if !lockedFilterKeys.contains(Self.materialKey)  { selectedMaterial = nil }
        if !lockedFilterKeys.contains(Self.statusKey)    { selectedStatus = nil }
        if !lockedFilterKeys.contains(Self.attentionKey) { selectedAttention = nil }
        if !lockedFilterKeys.contains(Self.groupKey)     { selectedGroup = nil }
    }
}

// MARK: - Action

enum DocumentFilterSheetAction {
    case applyFilters(_ filters: [String: AnyHashable])
}
