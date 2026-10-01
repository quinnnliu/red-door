//
//  AccessoriesDocumentFilterSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/30/26.
//

import SwiftUI

struct AccessoriesDocumentFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    var action: (Any?) -> Void

    // MARK: - Filter State

    @State private var selectedStatus: LocationStatus?
    @State private var selectedType: AccessoriesType?

    // MARK: - Data

    let availableTypes: [AccessoriesType]

    // MARK: - Filter Keys

    private static let statusKey = DocumentLocation.statusFilterKey
    private static let typeKey   = Accessories.CodingKeys.accessoriesTypeId.stringValue

    // MARK: - Init

    init(
        action: @escaping (Any?) -> Void,
        initialFilters: [String: AnyHashable] = [:],
        availableTypes: [AccessoriesType] = []
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

private extension AccessoriesDocumentFilterSheet {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton(icon: SFSymbols.xmark)
            },
            header: {
                Text("Filter Accessories")
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

private extension AccessoriesDocumentFilterSheet {

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
