//
//  ItemDocumentListViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import SwiftUI

struct ItemDocumentListViewV2: View {
    @State private var viewModel: DocumentListViewModelV2<ItemV2> = DocumentListViewModelV2<ItemV2>()
    @Binding var path: NavigationPath
    let itemRepo: ItemRepository

    init(
        path: Binding<NavigationPath>,
        itemRepo: ItemRepository = ItemRepository()
    ) {
        self._path = path
        self.itemRepo = itemRepo
    }

    @State private var searchFocused: Bool = false
    @State private var createDocumentSheetType: CreateDocumentSheetType? = nil
    @State private var showScannerSheet: Bool = false
    @State private var scannedItemId: String? = nil

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 12) {
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
            .fullScreenCover(item: $createDocumentSheetType) { type in
                type.view
            }
            .sheet(isPresented: $showScannerSheet) {
                ItemScannerView(scannedItemId: $scannedItemId)
            }
            .onChange(of: scannedItemId) { _, newValue in
                guard let newValue else { return }
                handleScannedItemId(newValue)
            }
            .rootNavigationDestinationsV2(path: $path)
        }
    }
}

extension ItemDocumentListViewV2 {
    // MARK: - TopBar

    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                Text("Inventory")
                    .font(.system(.title2, design: .default))
                    .bold()
                    .foregroundStyle(.red)
            },
            header: {
                EmptyView()
            },
            trailingView: {
                TrailingIconGroup
            }
        ).tint(.red)
    }

    // MARK: - TrailingIconGroup

    private var TrailingIconGroup: some View {
        HStack(spacing: 8) {
            Group {
                RDButton(variant: .outline, size: .icon, leadingIcon: "magnifyingglass", iconBold: true, fullWidth: false) {
                    searchFocused = true
                }

                RDButton(variant: .outline, size: .icon, leadingIcon: "qrcode.viewfinder", iconBold: true, fullWidth: false) {
                    showScannerSheet = true
                }

                CreateDocumentMenu
            }
            .foregroundColor(.red)
        }
    }
    
    // MARK: - CreateDocumentMenu
    private var CreateDocumentMenu: some View {
        Menu {
            Button("Item", systemImage: SFSymbols.couchFill) {
                createDocumentSheetType = .item
            }
            
            Button("Essentials", systemImage: SFSymbols.starCircleFill) {
                createDocumentSheetType = .essentials
            }

            Button("Accessories", systemImage: SFSymbols.booksVerticalFill) {
                createDocumentSheetType = .accessories
            }
        } label: {
            RDButton(variant: .outline, size: .icon, leadingIcon: "plus", iconBold: true, fullWidth: false) { }.allowsHitTesting(false)
        }
    }

    // MARK: - Inventory List
    private var InventoryList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.documents, id: \.id) { item in
                    NavigationLink(value: NavigationDestination.itemDetailView(item)) {
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

    // MARK: - LoadMoreButton
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
        } else {
            RDButton(
                variant: .outline,
                label: "No More Items",
                fullWidth: true
            ) {
            }
            .allowsHitTesting(false)
            .padding(.vertical, 4)
        }
    }
}

private extension ItemDocumentListViewV2 {
    enum CreateDocumentSheetType: Identifiable {
        case item
        case essentials
        case accessories

        var id: Self { self }

        var view: AnyView {
            switch self {
            case .item:
                AnyView(CreateItemsViewV2())
            case .essentials:
                AnyView(CreateEssentialsGroupView())
            case .accessories:
                AnyView(CreateAccessoriesView())
            }
        }
    }
    
    // MARK: - handleAction
    
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
                        await viewModel.updateFilter(key: "type", value: newType.rawValue)
                    } else {
                        await viewModel.removeFilter(key: "type")
                    }
                }
            }
        default:
            print("ERROR: Untracked action")
        }
    }
    
    // MARK: - handleScannedItemId
    
    func handleScannedItemId(_ id: String) {
        Task {
            let item = try await itemRepo.get(id: id)
            path.append(item)
        }
        scannedItemId = nil
    }
}
