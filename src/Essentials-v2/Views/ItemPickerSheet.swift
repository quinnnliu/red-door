//
//  ItemPickerSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

import SwiftUI

struct ItemPickerSheet: View {
    @State private var listViewModel: DocumentListViewModelV2<ItemV2>
    @State private var searchFocused: Bool = false
    @State private var showFilterSheet: Bool = false
    @State private var activeFilters: [String: AnyHashable] = [:]

    private let title: String
    private let selectedIds: Set<String>
    private let onSelect: (ItemV2) -> Void

    init(
        title: String = "Add Items",
        selectedIds: Set<String>,
        onSelect: @escaping (ItemV2) -> Void
    ) {
        self.title = title
        self.selectedIds = selectedIds
        self.onSelect = onSelect
        self.listViewModel = DocumentListViewModelV2<ItemV2>(
            defaultFilters: [ItemV2.CodingKeys.status.rawValue: LocationStatus.inStorage.rawValue]
        )
    }

    // MARK: - Body

    var body: some View {
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
            await listViewModel.refresh()
        }
        .sheet(isPresented: $showFilterSheet) {
            ItemV2DocumentFilterSheet(action: handleAction(_:), initialFilters: activeFilters)
        }
    }
}

// MARK: - Subviews

private extension ItemPickerSheet {

    var TopBar: some View {
        TopAppBar(
            leadingView: {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(.title2, design: .default))
                        .bold()
                        .foregroundStyle(.red)
                    
                    RDButton(variant: activeFilters.isEmpty ? .secondary : .red, size: .icon, leadingIcon: SFSymbols.sliderHorizontal3, iconBold: true, fullWidth: false) {
                        showFilterSheet = true
                    }
                }
            },
            header: {
                EmptyView()
            },
            trailingView: {
                RDButton(variant: .outline, size: .icon, leadingIcon: SFSymbols.magnifyingglass, iconBold: true, fullWidth: false) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        searchFocused = true
                    }
                }
            }
        )
    }

    var ItemList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(listViewModel.documents, id: \.id) { item in
                    let isSelected = selectedIds.contains(item.id)
                    Button {
                        onSelect(item)
                    } label: {
                        ItemDocumentListItemView(item: item)
                            .overlay(alignment: .trailing) {
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.red)
                                        .padding(.trailing, 12)
                                }
                            }
                            .opacity(isSelected ? 0.5 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isSelected)
                }

                LoadMoreButton
            }
        }
        .refreshable {
            await listViewModel.refresh()
        }
    }

    @ViewBuilder
    var LoadMoreButton: some View {
        if listViewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else if listViewModel.hasMore {
            RDButton(
                variant: .outline,
                label: "Load More",
                fullWidth: true
            ) {
                Task { await listViewModel.loadMore() }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - handleAction

private extension ItemPickerSheet {
    func handleAction(_ action: Any?) {
        guard let action else { return }
        switch action {
        case let searchAction as SearchBarAction:
            Task { await listViewModel.handleSearchAction(searchAction) }
        case let filterAction as DocumentFilterSheetAction:
            switch filterAction {
            case .applyFilters(let filters):
                activeFilters = filters
                Task { await listViewModel.setFilters(filters) }
            }
        default:
            print("ERROR: Untracked action")
        }
    }
}
