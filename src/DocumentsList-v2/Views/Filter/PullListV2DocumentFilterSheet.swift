//
//  PullListV2DocumentFilterSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/23/26.
//

import SwiftUI

struct PullListV2DocumentFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    var action: (Any?) -> Void

    // MARK: - Filter State

    @State private var selectedInstallDate: Date?
    @State private var selectedUninstallDate: Date?
    @State private var selectedState: NewEnglandState?
    @State private var selectedTown: String

    // MARK: - Init

    init(initialFilters: [String: AnyHashable] = [:], action: @escaping (Any?) -> Void) {
        self.action = action

        let installString = initialFilters[PullListV2.CodingKeys.installDate.stringValue] as? String
        let uninstallString = initialFilters[PullListV2.CodingKeys.uninstallDate.stringValue] as? String

        let formatter = Date.FormatStyle().year().month().day()
        _selectedInstallDate = State(initialValue: installString.flatMap { try? Date($0, strategy: formatter) })
        _selectedUninstallDate = State(initialValue: uninstallString.flatMap { try? Date($0, strategy: formatter) })
        _selectedState = State(initialValue: (initialFilters[Address.firestoreKey(.state)] as? String).flatMap(NewEnglandState.init(rawValue:)))
        _selectedTown = State(initialValue: initialFilters[Address.firestoreKey(.town)] as? String ?? "")
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            DragIndicator()
                .padding(.top, 8)

            TopBar

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    DateFilterRow(title: "Install Date", selectedDate: $selectedInstallDate)
                    DateFilterRow(title: "Uninstall Date", selectedDate: $selectedUninstallDate)
                    FilterPickerRow(selectedItem: $selectedState, items: NewEnglandState.allCases, title: "State")
                    TownFilterRow
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

private extension PullListV2DocumentFilterSheet {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton(icon: SFSymbols.xmark)
            },
            header: {
                Text("Filter Pull Lists")
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

    var TownFilterRow: some View {
        HStack {
            Text("Town")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Spacer()
            TextField("Any", text: $selectedTown)
                .multilineTextAlignment(.trailing)
                .font(.subheadline)
                .foregroundStyle(selectedTown.isEmpty ? .secondary : Color.red)
                .frame(maxWidth: 120)
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

// MARK: - DateFilterRow

private struct DateFilterRow: View {
    let title: String
    @Binding var selectedDate: Date?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedDate != nil {
                    Button {
                        withAnimation(.snappy) { selectedDate = nil }
                    } label: {
                        Image(systemName: SFSymbols.xmark)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
                if let date = selectedDate {
                    DatePicker("", selection: Binding(
                        get: { date },
                        set: { selectedDate = $0 }
                    ), displayedComponents: [.date])
                    .labelsHidden()
                } else {
                    Button {
                        withAnimation(.snappy) { selectedDate = .init() }
                    } label: {
                        Text("Any")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Capsule().fill(Color(.systemGray5)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 12)
            Divider()
        }
    }
}

// MARK: - Actions

private extension PullListV2DocumentFilterSheet {

    var hasActiveFilters: Bool {
        selectedInstallDate != nil
        || selectedUninstallDate != nil
        || selectedState != nil
        || !selectedTown.isEmpty
    }

    func buildFilterDictionary() -> [String: AnyHashable] {
        var filters: [String: AnyHashable] = [:]
        let formatter = Date.FormatStyle().year().month().day()
        if let install = selectedInstallDate {
            filters[PullListV2.CodingKeys.installDate.stringValue] = install.formatted(formatter)
        }
        if let uninstall = selectedUninstallDate {
            filters[PullListV2.CodingKeys.uninstallDate.stringValue] = uninstall.formatted(formatter)
        }
        if let state = selectedState {
            filters[Address.firestoreKey(.state)] = state.rawValue
        }
        if !selectedTown.isEmpty {
            filters[Address.firestoreKey(.town)] = selectedTown.lowercased()
        }
        return filters
    }

    func applyFilters() {
        action(DocumentFilterSheetAction.applyFilters(buildFilterDictionary()))
        dismiss()
    }

    func resetFilters() {
        selectedInstallDate = nil
        selectedUninstallDate = nil
        selectedState = nil
        selectedTown = ""
    }
}
