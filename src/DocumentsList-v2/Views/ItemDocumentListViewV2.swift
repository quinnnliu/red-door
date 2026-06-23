//
//  ItemDocumentListViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import SwiftUI

struct ItemDocumentListViewV2: View {
    @Binding var path: NavigationPath
    let itemRepo: ItemRepository

    init(
        path: Binding<NavigationPath>,
        itemRepo: ItemRepository = ItemRepository()
    ) {
        self._path = path
        self.itemRepo = itemRepo
    }

    // MARK: - Segment State

    @State private var selectedSegment: InventorySegment = .items

    @State private var itemsVM: DocumentListViewModelV2<ItemV2> = DocumentListViewModelV2<ItemV2>()
    @State private var essentialsVM: DocumentListViewModelV2<EssentialsGroup> = DocumentListViewModelV2<EssentialsGroup>(pageSize: 50)
    @State private var accessoriesVM: DocumentListViewModelV2<Accessories> = DocumentListViewModelV2<Accessories>(pageSize: 50)

    // MARK: - UI State

    @State private var searchFocused: Bool = false
    @State private var createDocumentSheetType: InventorySegment? = nil
    @State private var filterDocumentSheetType: InventorySegment? = nil
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

                HStack(spacing: 8) {
                    Picker("Inventory", selection: $selectedSegment) {
                        ForEach(InventorySegment.allCases, id: \.self) { segment in
                            Text(segment.title).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    FilterButton(filtersActive)
                }

                switch selectedSegment {
                case .items:
                    ItemsListContent
                case .essentials:
                    EssentialsListContent
                case .accessories:
                    AccessoriesListContent
                }
            }
            .frameTop()
            .frameHorizontalPadding()
            .task {
                await itemsVM.refresh()
            }
            .fullScreenCover(item: $createDocumentSheetType) { type in
                type.createDocumentSheet
            }
            .sheet(item: $filterDocumentSheetType) { type in
                type.filterSheet(action: handleAction(_:), initialFilters: activeFilters(for: type))
                    .presentationDetents([.large])
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
    
    // MARK: - FilterButton
    private func FilterButton(_ filtersActive: Bool = false) -> some View {
        RDButton(
            variant: filtersActive ? .red : .secondary,
            size: .icon,
            leadingIcon: SFSymbols.sliderHorizontal3,
            iconBold: true
        ) {
            filterDocumentSheetType = selectedSegment
        }
    }
    
    private var filtersActive: Bool {
        switch selectedSegment {
        case .items: itemsVM.activeFiltersApplied
        case .essentials: essentialsVM.activeFiltersApplied
        case .accessories: accessoriesVM.activeFiltersApplied
        }
    }

    private func activeFilters(for segment: InventorySegment) -> [String: AnyHashable] {
        switch segment {
        case .items:       itemsVM.activeFilters
        case .essentials:  essentialsVM.activeFilters
        case .accessories: accessoriesVM.activeFilters
        }
    }

    // MARK: - CreateDocumentMenu
    private var CreateDocumentMenu: some View {
        Menu {
            Button("Item", systemImage: SFSymbols.couchFill) {
                createDocumentSheetType = .items
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

    // MARK: - Items List

    private var ItemsListContent: some View {
        DocumentListSection(
            viewModel: itemsVM,
            noMoreLabel: "No More Items",
            destination: { .itemDetailView($0) },
            rowContent: { ItemDocumentListItemView(item: $0) }
        )
    }

    // MARK: - Essentials List

    private var EssentialsListContent: some View {
        DocumentListSection(
            viewModel: essentialsVM,
            noMoreLabel: "No More Essentials",
            destination: { .essentialsGroupDetailView($0) },
            rowContent: { EssentialsGroupListItemView(group: $0) }
        )
        .task {
            if essentialsVM.documents.isEmpty {
                await essentialsVM.refresh()
            }
        }
    }

    // MARK: - Accessories List

    private var AccessoriesListContent: some View {
        DocumentListSection(
            viewModel: accessoriesVM,
            noMoreLabel: "No More Accessories",
            destination: { .accessoriesDetailView($0) },
            rowContent: { AccessoriesListItemView(accessories: $0) }
        )
        .task {
            if accessoriesVM.documents.isEmpty {
                await accessoriesVM.refresh()
            }
        }
    }
}

private extension ItemDocumentListViewV2 {

    // MARK: - InventorySegment

    enum InventorySegment: Int, CaseIterable, Identifiable {
        case items = 0
        case essentials = 1
        case accessories = 2

        var title: String {
            switch self {
            case .items: "Items"
            case .essentials: "Essentials"
            case .accessories: "Accessories"
            }
        }
        
        var id: String {
            "\(self)"
        }
        
        @ViewBuilder
        var createDocumentSheet: some View {
            switch self {
            case .items:
                CreateItemsViewV2()
            case .essentials:
                CreateEssentialsGroupView()
            case .accessories:
                CreateAccessoriesView()
            }
        }
        
        @ViewBuilder
        func filterSheet(action: @escaping (Any?) -> Void, initialFilters: [String: AnyHashable] = [:]) -> some View {
            switch self {
            case .items:
                ItemV2DocumentFilterSheet(action: action, initialFilters: initialFilters)
            case .essentials:
                Text("FilterSheetView for \(self.title)")
            case .accessories:
                Text("FilterSheetView for \(self.title)")
            }
        }
    }

    // MARK: - handleAction

    func handleAction(_ action: Any?) {
        guard let action else { return }

        switch action {
        case let searchAction as SearchBarAction:
            Task {
                switch selectedSegment {
                case .items:
                    await itemsVM.handleSearchAction(searchAction)
                case .essentials:
                    await essentialsVM.handleSearchAction(searchAction)
                case .accessories:
                    await accessoriesVM.handleSearchAction(searchAction)
                }
            }
        case let filterAction as ItemInventoryFilterViewAction:
            switch filterAction {
            case .selectItemType(let newType):
                Task {
                    if let newType {
                        await itemsVM.updateFilter(key: "type", value: newType.rawValue)
                    } else {
                        await itemsVM.removeFilter(key: "type")
                    }
                }
            }
        case let filterAction as DocumentFilterSheetAction:
            Task {
                switch filterAction {
                case .applyFilters(let filters):
                    switch selectedSegment {
                    case .items: await itemsVM.setFilters(filters)
                    case .essentials: await essentialsVM.setFilters(filters)
                    case .accessories: await accessoriesVM.setFilters(filters)
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
