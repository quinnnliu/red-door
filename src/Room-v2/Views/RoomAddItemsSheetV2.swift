//
//  RoomAddItemsSheetV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import SwiftUI

struct RoomAddItemsSheetV2: View {
    @State private var viewModel: DocumentListViewModelV2<ItemV2> = DocumentListViewModelV2<ItemV2>(
        defaultFilters: [ItemV2.CodingKeys.status.rawValue: ItemStatus.inStorage.rawValue]
    )
    
    @State private var path: NavigationPath = NavigationPath()
    let itemRepo: ItemRepository = ItemRepository()
    let room: RoomV2
    
    init(
        room: RoomV2
    ) {
        self.room = room
    }
    
    @State private var searchFocused: Bool = false
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 12) {
                DragIndicator()

                if searchFocused {
                    SearchBarV2(isActive: $searchFocused, action: handleAction(_:))
                } else {
                    TopBar
                }
                
                ItemInventoryFilterView(action: handleAction(_:))
                
                InventoryList
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

extension RoomAddItemsSheetV2 {
    // MARK: Top Bar
    
    @ViewBuilder
    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                Text("Available Items")
                    .font(.system(.title2, design: .default))
                    .bold()
                    .foregroundStyle(.red)
            },
            header: {
                EmptyView()
            },
            trailingView: {
                RDButton(variant: .outline, size: .icon, leadingIcon: "magnifyingglass", iconBold: true, fullWidth: false) {
                    searchFocused = true
                }
            }
        )
    }
    
    // MARK: Inventory List
    
    @ViewBuilder
    private var InventoryList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.documents, id: \.id) { item in
                    NavigationLink(value: NavigationDestination.addItemToRoomDetailView(item, room: room)) {
                        ItemListItemView(item: item)
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

// MARK: handleAction

private extension RoomAddItemsSheetV2 {
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
        case let filterAction as ItemInventoryFilterViewAction:
            switch filterAction {
            case .selectItemType(let newType):
                Task {
                    if let newType {
                        await viewModel.updateFilter(key: ItemV2.CodingKeys.type.stringValue, value: newType.rawValue)
                    } else {
                        await viewModel.removeFilter(key: ItemV2.CodingKeys.type.stringValue)
                    }
                }
            }
        default:
            print("ERROR: Untracked action")
        }
    }
}


// #Preview {
//    RoomAddItemsSheet(room: Room.MOCK_DATA[0], showSheet: .constant(true))
// }
