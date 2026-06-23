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

    // MARK: - Init

    init(action: @escaping (Any?) -> Void, initialFilters: [String: AnyHashable] = [:]) {
        self.action = action
        _selectedType      = State(initialValue: (initialFilters[ItemV2.CodingKeys.type.stringValue] as? String).flatMap(ItemType.init(rawValue:)))
        _selectedColor     = State(initialValue: (initialFilters[ItemV2.CodingKeys.color.stringValue] as? String).flatMap(ItemColor.init(rawValue:)))
        _selectedMaterial  = State(initialValue: (initialFilters[ItemV2.CodingKeys.material.stringValue] as? String).flatMap(ItemMaterial.init(rawValue:)))
        _selectedStatus    = State(initialValue: (initialFilters[ItemV2.CodingKeys.status.stringValue] as? String).flatMap(LocationStatus.init(rawValue:)))
        _selectedAttention = State(initialValue: initialFilters[ItemV2.CodingKeys.attention.stringValue] as? Bool)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            DragIndicator()
                .padding(.top, 8)
            
            TopBar

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    FilterPickerRow(selectedItem: $selectedType, items: ItemType.allCases, title: "Type")
                    FilterPickerRow(selectedItem: $selectedStatus, items: LocationStatus.allCases, title: "Status")
                    FilterPickerRow(selectedItem: $selectedColor, items: ItemColor.allCases, title: "Color")
                    FilterPickerRow(selectedItem: $selectedMaterial, items: ItemMaterial.allCases, title: "Material")
                    AttentionRow
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

    var ApplyButton: some View {
        RDButton(variant: .red, label: "Apply Filters", fullWidth: true) {
            applyFilters()
        }
    }
}

// MARK: - Actions

private extension ItemV2DocumentFilterSheet {

    var hasActiveFilters: Bool {
        selectedType != nil
        || selectedColor != nil
        || selectedMaterial != nil
        || selectedStatus != nil
        || selectedAttention != nil
    }

    func buildFilterDictionary() -> [String: AnyHashable] {
        var filters: [String: AnyHashable] = [:]
        if let type = selectedType { filters[ItemV2.CodingKeys.type.stringValue] = type.rawValue }
        if let color = selectedColor { filters[ItemV2.CodingKeys.color.stringValue] = color.rawValue }
        if let material = selectedMaterial { filters[ItemV2.CodingKeys.material.stringValue] = material.rawValue }
        if let status = selectedStatus { filters[ItemV2.CodingKeys.status.stringValue] = status.rawValue }
        if let attention = selectedAttention { filters[ItemV2.CodingKeys.attention.stringValue] = attention }
        return filters
    }

    func applyFilters() {
        action(DocumentFilterSheetAction.applyFilters(buildFilterDictionary()))
        dismiss()
    }

    func resetFilters() {
        selectedType = nil
        selectedColor = nil
        selectedMaterial = nil
        selectedStatus = nil
        selectedAttention = nil
    }
}

// MARK: - Action

enum DocumentFilterSheetAction {
    case applyFilters(_ filters: [String: AnyHashable])
}
