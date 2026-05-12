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
        itemRepo: ItemRepository
    ) {
        self._viewModel = State(initialValue: viewModel)
        self._path = path
        self.itemRepo = itemRepo
    }
    
    // Filter Variables
    
    @State private var searchText: String = ""
    // TODO: implement filter view
//    @State private var selectedType: ModelTypeV2?
    
    // View Modifier Variables
    
    @State private var isLoadingModels: Bool = false
    @State private var searchFocused: Bool = false
    @FocusState private var searchTextFocused: Bool
    
    @State private var showCreateModelCover: Bool = false
    @State private var showScannerSheet: Bool = false
    @State var scannedItemId: String? = nil
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 12) {
                if searchFocused {
                    SearchBar()
                } else {
                    TopBar()
                }
                
                InventoryList()
                
                Spacer()
            }
            .frameTop()
            .frameHorizontalPadding()
            .task {
                await viewModel.loadInitialDocuments()
            }
            .onChange(of: path) {
                searchFocused = false
            }
            .fullScreenCover(isPresented: $showCreateModelCover) {
                CreateModelView()
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
    
    func handleScannedItemId(_ id: String) {
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
        ).tint(.red)
    }
    
    // MARK: Search Bar
    
    @ViewBuilder
    private func SearchBar() -> some View {
        SearchBarComponent(
            searchText: $searchText,
            searchFocused: $searchFocused,
            searchTextFocused: $searchTextFocused,
            onSubmit: {
                Task {
                    await viewModel.loadMoreDocuments()
//                    await fetchModels(initial: true, searchText: searchText, modelType: selectedType)
                }
            }
        )
    }
    
    // MARK: Inventory List
    @ViewBuilder
    private func InventoryList() -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.documentsArray, id: \.id) { model in
                    NavigationLink(value: model) {
                        Text("MODEL V2 LIST ITEM VIEW")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if isLoadingModels {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    RDButton(variant: .outline, text: "Load More") {
                        Task {
                            await viewModel.loadMoreDocuments()
                        }
                    }
                }
            }
        }
        .refreshable {
            Task {
                if !isLoadingModels {
                    await viewModel.loadMoreDocuments()
                }
            }
        }
    }
}
