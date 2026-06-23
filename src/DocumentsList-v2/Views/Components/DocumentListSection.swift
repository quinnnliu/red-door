//
//  DocumentListSection.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

import SwiftUI

struct DocumentListSection<T: RDDocument, RowContent: View>: View {
    let viewModel: DocumentListViewModelV2<T>
    let noMoreLabel: String
    let destination: (T) -> NavigationDestination
    @ViewBuilder let rowContent: (T) -> RowContent

    var body: some View {
        ScrollView {
            LazyVStack(spacing: .zero) {
                ForEach(viewModel.documents, id: \.id) { document in
                    NavigationLink(value: destination(document)) {
                        rowContent(document)
                            .padding(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                DocumentLoadMoreButton(
                    isLoading: viewModel.isLoading,
                    hasMore: viewModel.hasMore,
                    noMoreLabel: noMoreLabel,
                    loadMore: { await viewModel.loadMore() }
                )
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}
