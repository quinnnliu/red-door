//
//  SelectDocumentSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import SwiftUI

struct SelectDocumentSheet<T: RDDocument, Footer: View>: View {
    @Environment(\.dismiss) private var dismiss

    private let title: String
    private let documents: [T]
    private let refreshAction: (() -> Void)?
    private let action: (Any?) -> Void
    private let footer: Footer

    init(
        title: String,
        documents: [T],
        refreshAction: (() -> Void)? = nil,
        action: @escaping (Any?) -> Void,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.documents = documents
        self.refreshAction = refreshAction
        self.action = action
        self.footer = footer()
    }

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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.displayName)
                                    .bold()

                                if let metadata = doc.metadata {
                                    Text(metadata)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray5))
                            .cornerRadius(Constants.CornerRadius.medium)
                            .foregroundColor(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            if !(footer is EmptyView) {
                Button {
                    action(SelectDocumentSheetAction<T>.footerAction)
                    dismiss()
                } label: {
                    footer
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .presentationDetents([.medium])
    }
}

extension SelectDocumentSheet where Footer == EmptyView {
    init(
        title: String,
        documents: [T],
        refreshAction: (() -> Void)? = nil,
        action: @escaping (Any?) -> Void
    ) {
        self.init(
            title: title,
            documents: documents,
            refreshAction: refreshAction,
            action: action,
            footer: { EmptyView() }
        )
    }
}

enum SelectDocumentSheetAction<T: RDDocument> {
    case selected(T)
    case footerAction
}

/// Mirrors the press feedback `RDButton` applies to itself, for footers passed
/// in as `isButton: false` labels.
private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(Constants.Animation.snappy, value: configuration.isPressed)
    }
}
