//
//  DocumentLoadMoreButton.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

import SwiftUI

struct DocumentLoadMoreButton: View {
    let isLoading: Bool
    let hasMore: Bool
    let noMoreLabel: String
    let loadMore: () async -> Void

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if hasMore {
                RDButton(
                    variant: .outline,
                    label: "Load More",
                    fullWidth: true
                ) {
                    Task { await loadMore() }
                }
            } else {
                Text(noMoreLabel)
                    .padding(.top, 12)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}
