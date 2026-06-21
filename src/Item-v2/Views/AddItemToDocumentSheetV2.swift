//
//  AddItemToDocumentSheetV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

import SwiftUI

struct AddItemToDocumentSheetV2: View {
    @State private var viewModel: DocumentListViewModelV2<ItemV2>
    @State private var path: NavigationPath = NavigationPath()
    @State private var searchFocused: Bool = false

    private let title: String
    private let makeContext: (ItemV2) -> AddItemDocumentContext

    init(
        title: String = "Available Items",
        makeContext: @escaping (ItemV2) -> AddItemDocumentContext
    ) {
        self.title = title
        self.makeContext = makeContext
        self.viewModel = DocumentListViewModelV2<ItemV2>(defaultFilters: [ItemV2.CodingKeys.status.rawValue: LocationStatus.inStorage.rawValue])
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 12) {
                DragIndicator()

                if searchFocused {
                    SearchBarV2(isActive: $searchFocused, action: handleAction(_:))
                } else {
                    TopBar
                }

                ItemList
            }
            .frameTop()
            .frameHorizontalPadding()
            .task {
                await viewModel.refresh()
            }
            .rootNavigationDestinationsV2(path: $path)
        }
    }
}

// MARK: - Subviews

extension AddItemToDocumentSheetV2 {

    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                Text(title)
                    .font(.system(.title2, design: .default))
                    .bold()
                    .foregroundStyle(.red)
            },
            header: {
                EmptyView()
            },
            trailingView: {
                RDButton(variant: .outline, size: .icon, leadingIcon: SFSymbols.magnifyingglass, iconBold: true, fullWidth: false) {
                    searchFocused = true
                }
            }
        )
    }

    private var ItemList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.documents, id: \.id) { item in
                    NavigationLink(value: NavigationDestination.addItemToDocumentDetailView(context: makeContext(item))) {
                        ItemDocumentListItemView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                LoadMoreButton
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private var LoadMoreButton: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else if viewModel.hasMore {
            RDButton(
                variant: .outline,
                label: "Load More",
                fullWidth: true
            ) {
                Task { await viewModel.loadMore() }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - handleAction

private extension AddItemToDocumentSheetV2 {
    func handleAction(_ action: Any?) {
        guard let action else { return }

        switch action {
        case let searchAction as SearchBarAction:
            switch searchAction {
            case .search(let text):
                Task { await viewModel.search(text: text) }
            case .cancel:
                Task { await viewModel.refresh() }
            }
        default:
            print("ERROR: Untracked action")
        }
    }
}
