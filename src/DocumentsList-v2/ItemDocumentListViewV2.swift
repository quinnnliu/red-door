//
//  ItemDocumentListViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import SwiftUI

struct ItemDocumentListViewV2: View {
    @State private var viewModel: DocumentListViewModelV2<ItemV2>
    @Binding var path: NavigationPath
    let itemRepo: ItemRepository
    
    init(
        viewModel: DocumentListViewModelV2<ItemV2> = DocumentListViewModelV2<ItemV2>(),
        path: Binding<NavigationPath>,
        itemRepo: ItemRepository = ItemRepository()
    ) {
        self._viewModel = State(initialValue: viewModel)
        self._path = path
        self.itemRepo = itemRepo
    }
    
    @State private var searchText: String = ""
    @State private var searchFocused: Bool = false
    @FocusState private var searchTextFocused: Bool
    
    @State private var showCreateModelCover: Bool = false
    @State private var showScannerSheet: Bool = false
    @State private var scannedItemId: String? = nil
    
    private var selectedType: ItemType? {
        viewModel.activeTypeFilter.flatMap(ItemType.init(rawValue:))
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 12) {
                if searchFocused {
                    SearchBar()
                } else {
                    TopBar()
                }
                
                ItemInventoryFilterView(
                    selectedType: selectedType,
                    onSelect: { type in
                        Task { await viewModel.applyTypeFilter(type?.rawValue) }
                    }
                )
                
                InventoryList()
                
                Spacer()
            }
            .frameTop()
            .frameHorizontalPadding()
            .task {
                await viewModel.refresh()
            }
            .onChange(of: path) {
                searchFocused = false
            }
            .fullScreenCover(isPresented: $showCreateModelCover) {
                CreateItemsViewV2()
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
    
    private func handleScannedItemId(_ id: String) {
        Task {
            let item = try await itemRepo.get(id: id)
            path.append(item)
        }
        scannedItemId = nil
    }
}

extension ItemDocumentListViewV2 {
    // MARK: Top Bar
    
    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(
            leadingIcon: {
                Text("Inventory")
                    .font(.system(.title2, design: .default))
                    .bold()
                    .foregroundStyle(.red)
            },
            header: {
                EmptyView()
            },
            trailingIcon: {
                TrailingIconGroup
            }
        ).tint(.red)
    }
    
    // MARK: Search Bar
    
    @ViewBuilder
    private func SearchBar() -> some View {
        SearchBarComponent( // TODO: explore how to make this component own the viewstate for this
            searchText: $searchText,
            searchFocused: $searchFocused,
            searchTextFocused: $searchTextFocused,
            onSubmit: {
                Task {
                    await viewModel.search(text: searchText)
                }
            }
        )
    }
    
    // MARK: Trailing
    private var TrailingIconGroup: some View {
        HStack(spacing: 8) {
            Group {
                if !searchFocused {
                    RDButton(variant: .outline, size: .icon, leadingIcon: "magnifyingglass", iconBold: true, fullWidth: false) {
                        searchFocused = true
                        searchTextFocused = true
                    }
                }
                
                RDButton(variant: .outline, size: .icon, leadingIcon: "qrcode.viewfinder", iconBold: true, fullWidth: false) {
                    showScannerSheet = true
                }
                
                RDButton(variant: .outline, size: .icon, leadingIcon: "plus", iconBold: true, fullWidth: false) {
                    showCreateModelCover = true
                }
            }
            .foregroundColor(.red)
        }
    }
    
    // MARK: Inventory List
    
    @ViewBuilder
    private func InventoryList() -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.documentsArray, id: \.id) { item in
                    NavigationLink(value: item) {
                        ItemListItemView(item: item)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        if item == viewModel.documentsArray.last {
                            Task {
                                await viewModel.loadMoreDocuments()
                            }
                        }
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .refreshable {
            if !viewModel.isLoading {
                await viewModel.refresh()
            }
        }
    }
}
