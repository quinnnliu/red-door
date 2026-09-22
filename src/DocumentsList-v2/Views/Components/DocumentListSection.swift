//
//  DocumentListSection.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

import SwiftUI

enum DocumentListSectionAction {
    case loadMore
}

struct DocumentListSection<T: RDDocument, RowContent: View>: View {
    let viewModel: DocumentListViewModelV2<T>
    let noMoreLabel: String
    let action: (Any?) -> Void
    @ViewBuilder let rowContent: (T) -> RowContent

    var body: some View {
        ScrollView {
            LazyVStack(spacing: .zero) {
                ForEach(viewModel.documents, id: \.id) { document in
                    rowContent(document)
                        .padding(4)
                }

                DocumentLoadMoreButton(
                    isLoading: viewModel.isLoading,
                    hasMore: viewModel.hasMore,
                    noMoreLabel: noMoreLabel,
                    loadMore: { action(DocumentListSectionAction.loadMore) }
                )
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}
