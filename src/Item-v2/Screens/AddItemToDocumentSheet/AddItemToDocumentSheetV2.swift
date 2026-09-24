//
//  AddItemToDocumentSheetV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

import SwiftUI

struct AddItemToDocumentSheetV2: View {
    @State private var documentListViewModel: DocumentListViewModelV2<ItemV2>
//    @State private var viewModel: AddItemToDocumentSheetViewModel
    @State private var path: NavigationPath = NavigationPath()
    @State private var searchFocused: Bool = false
    @State private var showFilterSheet: Bool = false

    private let destination: ItemsListDestination
    private let title: String

    init(
        title: String = "Available Items",
        destination: ItemsListDestination,
        defaultFilters: [String: AnyHashable] =
        ["\(ItemV2.CodingKeys.location.rawValue).\(DocumentLocation.CodingKeys.status.rawValue)": LocationStatus.inStorage.rawValue,]
    ) {
        self.title = title
        self.destination = destination
//        self.viewModel = AddItemToDocumentSheetViewModel()
        self.documentListViewModel = DocumentListViewModelV2<ItemV2>(defaultFilters: defaultFilters)
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
                await documentListViewModel.refresh()
            }
            .rootNavigationDestinationsV2(path: $path)
            .sheet(isPresented: $showFilterSheet) {
                let allFilters = documentListViewModel.activeFilters
                    .merging(documentListViewModel.defaultFilters ?? [:]) { current, _ in current }
                ItemV2DocumentFilterSheet(
                    action: handleAction(_:),
                    initialFilters: allFilters,
                    availableGroups: [],
                    lockedFilterKeys: documentListViewModel.defaultFilterKeys
                )
            }
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
                HStack(spacing: 8) {
                    RDButton(variant: documentListViewModel.activeFiltersApplied ? .red : .outline, size: .icon, leadingIcon: SFSymbols.sliderHorizontal3, iconBold: true, fullWidth: false) {
                        showFilterSheet = true
                    }
                    RDButton(variant: .outline, size: .icon, leadingIcon: SFSymbols.magnifyingglass, iconBold: true, fullWidth: false) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            searchFocused = true
                        }
                    }
                }
            }
        )
    }

    private var ItemList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(documentListViewModel.documents, id: \.id) { item in
                    ItemListItemView(
                        item: item,
                        style: .addItemToDocument,
                        action: handleAction(_:)
                    )
                }

                LoadMoreButton
            }
        }
        .refreshable {
            await documentListViewModel.refresh()
        }
    }

    @ViewBuilder
    private var LoadMoreButton: some View {
        if documentListViewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else if documentListViewModel.hasMore {
            RDButton(
                variant: .outline,
                label: "Load More",
                fullWidth: true
            ) {
                Task { await documentListViewModel.loadMore() }
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
                Task { await documentListViewModel.search(text: text) }
            case .cancel:
                Task { await documentListViewModel.removeFilter(key: ItemV2.searchField) }
            }
        case let filterAction as DocumentFilterSheetAction:
            switch filterAction {
            case .applyFilters(let filters):
                Task { await documentListViewModel.setFilters(filters) }
            }
        case let itemListItemAction as ItemListItemAction:
            switch itemListItemAction {
            case .navigate(let item):
                path.append(NavigationDestination.addItemToDocumentDetailView(item: item, destination: destination))
            case .multiSelectSelection(let item):
                print("item selected")
            case .multiSelectDeselection(let item):
                print("item deselected")
            default:
                return
            }
        default:
            print("[ERROR]: Untracked action")
        }
    }
}
