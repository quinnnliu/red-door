//
//  ListDocumentFilterSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/23/26.
//

import SwiftUI

struct ListDocumentFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    var action: (Any?) -> Void

    // MARK: - Filter State

    @State private var selectedInstallDate: Date?
    @State private var selectedUninstallDate: Date?
    @State private var selectedState: NewEnglandState?
    @State private var selectedTown: String

    // MARK: - Data

    private let title: String

    // MARK: - Filter Keys

    // `PullListV2` and `InstalledListV2` share these Firestore field names.
    private static let installDateKey   = PullListV2.CodingKeys.installDate.stringValue
    private static let uninstallDateKey = PullListV2.CodingKeys.uninstallDate.stringValue
    private static let stateKey         = Address.firestoreKey(.state)
    private static let townKey          = Address.firestoreKey(.town)

    // MARK: - Init

    init(title: String, initialFilters: [String: AnyHashable] = [:], action: @escaping (Any?) -> Void) {
        self.title = title
        self.action = action

        _selectedInstallDate = State(initialValue: initialFilters[Self.installDateKey] as? Date)
        _selectedUninstallDate = State(initialValue: initialFilters[Self.uninstallDateKey] as? Date)
        _selectedState = State(initialValue: (initialFilters[Self.stateKey] as? String).flatMap(NewEnglandState.init(rawValue:)))
        _selectedTown = State(initialValue: initialFilters[Self.townKey] as? String ?? "")
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

private extension ListDocumentFilterSheet {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton(icon: SFSymbols.xmark)
            },
            header: {
                Text(title)
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
                        withAnimation(Constants.Animation.snappy) { selectedDate = nil }
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
                        withAnimation(Constants.Animation.snappy) { selectedDate = .init() }
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

private extension ListDocumentFilterSheet {

    var hasActiveFilters: Bool {
        selectedInstallDate != nil
        || selectedUninstallDate != nil
        || selectedState != nil
        || !selectedTown.isEmpty
    }

    func buildFilterDictionary() -> [String: AnyHashable] {
        var filters: [String: AnyHashable] = [:]
        // Match how the field is stored: `@DayGranular` pins list dates to the
        // start of their day, so the filter value has to be pinned the same way.
        if let install = selectedInstallDate {
            filters[Self.installDateKey] = Calendar.current.startOfDay(for: install)
        }
        if let uninstall = selectedUninstallDate {
            filters[Self.uninstallDateKey] = Calendar.current.startOfDay(for: uninstall)
        }
        if let state = selectedState {
            filters[Self.stateKey] = state.rawValue
        }
        if !selectedTown.isEmpty {
            filters[Self.townKey] = selectedTown.lowercased()
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
