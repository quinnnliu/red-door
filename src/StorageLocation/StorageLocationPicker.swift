//
//  StorageLocationPicker.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/29/26.
//

import SwiftUI

struct StorageLocationPicker: View {
    let locations: [StorageLocation]
    @Binding var selected: StorageLocation?
    let refreshAction: (() -> Void)?

    @State private var showPicker: Bool = false

    init(
        locations: [StorageLocation],
        selected: Binding<StorageLocation?>,
        refreshAction: (() -> Void)? = nil
    ) {
        self.locations = locations
        self._selected = selected
        self.refreshAction = refreshAction
    }

    // MARK: Body

    var body: some View {
        Button { showPicker = true } label: {
            HStack {
                Text("Storage Location:")
                    .foregroundStyle(.red)
                    .bold()

                Spacer()

                Text(valueLabel)
                    .foregroundStyle(locations.isEmpty ? Color.secondary : Color.blue)
            }
        }
        .buttonStyle(.plain)
        .disabled(locations.isEmpty)
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(Constants.CornerRadius.medium)
        .sheet(isPresented: $showPicker) {
            SelectDocumentSheet(
                title: "Select Storage Location",
                documents: locations,
                refreshAction: refreshAction
            ) { action in
                guard let action = action as? SelectDocumentSheetAction<StorageLocation>,
                      case .selected(let location) = action else { return }
                selected = location
            }
        }
    }

    private var valueLabel: String {
        if let selected { return selected.displayName }
        return locations.isEmpty ? "None — add one in Options" : "Select"
    }
}
