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
            // ScrollView absorbs the leftover height so the footer stays pinned to the bottom
            .frame(maxHeight: .infinity)

            // Guarded so the default (footer-less) sheets don't pick up an
            // empty button and the stack spacing that comes with it
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
