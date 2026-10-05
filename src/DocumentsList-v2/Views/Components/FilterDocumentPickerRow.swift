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

    @State private var showSheet = false

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
            Button {
                showSheet = true
            } label: {
                HStack(spacing: 4) {
                    Text(selection?.displayName ?? "Any")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                }
                .font(.subheadline)
                .foregroundStyle(selection != nil ? .red : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .sheet(isPresented: $showSheet) {
            SelectDocumentSheet(
                title: title,
                documents: options,
                action: handleAction,
                footer: {
                    RDButton(style: .red, label: "Any", fullWidth: true)
                }
            )
        }
    }
}

// MARK: - Actions

private extension FilterDocumentPickerRow {
    func handleAction(_ action: Any?) {
        switch action {
        case let action as SelectDocumentSheetAction<T>:
            switch action {
            case .selected(let document):
                selection = document
            case .footerAction:
                selection = nil
            }
        default: break
        }
    }
}
