//
//  FilterDocumentPickerRow.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/30/26.
//

import SwiftUI

/// Filter row for options that are Firestore documents (e.g. configuration types)
/// rather than `Filterable` enums.
struct FilterDocumentPickerRow<T: RDDocument>: View {
    @Binding var selection: T?

    private let options: [T]
    private let title: String

    init(title: String, selection: Binding<T?>, options: [T]) {
        self.title = title
        self._selection = selection
        self.options = options
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Spacer()
            Picker("", selection: $selection) {
                Text("Any").tag(Optional<T>.none)
                ForEach(options) { option in
                    Text(option.displayName).tag(Optional(option))
                }
            }
            .pickerStyle(.menu)
            .tint(selection != nil ? .red : .secondary)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}
