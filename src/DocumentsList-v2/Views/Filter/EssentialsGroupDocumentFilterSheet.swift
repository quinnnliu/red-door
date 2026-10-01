//
//  EssentialsGroupDocumentFilterSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/30/26.
//

import SwiftUI

struct EssentialsGroupDocumentFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    var action: (Any?) -> Void

    // MARK: - Filter State

    @State private var selectedStatus: LocationStatus?
    @State private var selectedType: EssentialsGroupType?

    // MARK: - Data

    let availableTypes: [EssentialsGroupType]

    // MARK: - Filter Keys

    private static let statusKey = DocumentLocation.statusFilterKey
    private static let typeKey   = EssentialsGroup.CodingKeys.essentialsTypeId.stringValue

    // MARK: - Init

    init(
        action: @escaping (Any?) -> Void,
        initialFilters: [String: AnyHashable] = [:],
        availableTypes: [EssentialsGroupType] = []
    ) {
        self.action = action
        self.availableTypes = availableTypes
        _selectedStatus = State(initialValue: (initialFilters[Self.statusKey] as? String).flatMap(LocationStatus.init(rawValue:)))
        let typeId = initialFilters[Self.typeKey] as? String
        _selectedType   = State(initialValue: availableTypes.first { $0.id == typeId })
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            DragIndicator()
                .padding(.top, 8)

            TopBar

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    FilterPickerRow(selectedItem: $selectedStatus, items: LocationStatus.allCases, title: "Status")
                    FilterDocumentPickerRow(title: "Type", selection: $selectedType, options: availableTypes)
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

private extension EssentialsGroupDocumentFilterSheet {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton(icon: SFSymbols.xmark)
            },
            header: {
                Text("Filter Essentials")
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

    var ApplyButton: some View {
        RDButton(variant: .red, label: "Apply Filters", fullWidth: true) {
            applyFilters()
        }
    }
}

// MARK: - Actions

private extension EssentialsGroupDocumentFilterSheet {

    var hasActiveFilters: Bool {
        selectedStatus != nil || selectedType != nil
    }

    func buildFilterDictionary() -> [String: AnyHashable] {
        var filters: [String: AnyHashable] = [:]
        if let status = selectedStatus { filters[Self.statusKey] = status.rawValue }
        if let type = selectedType     { filters[Self.typeKey] = type.id }
        return filters
    }

    func applyFilters() {
        action(DocumentFilterSheetAction.applyFilters(buildFilterDictionary()))
        dismiss()
    }

    func resetFilters() {
        selectedStatus = nil
        selectedType = nil
    }
}
