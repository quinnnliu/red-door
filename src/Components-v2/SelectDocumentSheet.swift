//
//  SelectDocumentSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import SwiftUI

struct SelectDocumentSheet<T: RDDocument>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let documents: [T]
    let action: (Any?) -> Void
    var refreshAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            DragIndicator()

            ZStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.red)
                if let refreshAction {
                    HStack {
                        Spacer()
                        Button(action: refreshAction) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ScrollView {
                LazyVStack {
                    ForEach(documents) { doc in
                        Button {
                            action(SelectDocumentSheetAction.selected(doc))
                            dismiss()
                        } label: {
                            Text(doc.displayName)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                                .foregroundColor(.primary)
                                .bold()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frameTop()
        .frameHorizontalPadding()
        .presentationDetents([.medium])
    }
}

enum SelectDocumentSheetAction<T: RDDocument> {
    case selected(T)
}
