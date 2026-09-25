//
//  AddItemToDocumentSheetV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

import SwiftUI

struct AddItemToDocumentSheetV2: View {
    @Environment(\.dismiss) private var dismiss
    @State private var documentListViewModel: DocumentListViewModelV2<ItemV2>
    @State private var viewModel: AddItemToDocumentSheetViewModel
    @State private var path: NavigationPath = NavigationPath()
    @State private var searchFocused: Bool = false
    @State private var showFilterSheet: Bool = false
    @State private var multiSelectEnabled: Bool = false

    private let title: String

    init(
        title: String = "Available Items",
        destination: AddItemsToListableDestination,
        defaultFilters: [String: AnyHashable] =
        ["\(ItemV2.CodingKeys.location.rawValue).\(DocumentLocation.CodingKeys.status.rawValue)": LocationStatus.inStorage.rawValue,]
    ) {
        self.title = title
        self.viewModel = AddItemToDocumentSheetViewModel(destination: destination)
        self.documentListViewModel = DocumentListViewModelV2<ItemV2>(defaultFilters: defaultFilters)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                BodyContent

                if viewModel.isLoading {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    LoadingIndicator
                }
            }
        }
    }
}

// MARK: - BodyContent

private extension AddItemToDocumentSheetV2 {
    var BodyContent: some View {
        VStack(spacing: 12) {
            DragIndicator()

            TopRow

            ItemList
            
            SelectedItemsSection
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
        .alert(viewModel.alertText, isPresented: $viewModel.showAlert) {
            Button("OK") { }
        }
    }
}

private extension AddItemToDocumentSheetV2 {
    var TopRow: some View {
        Group {
            if searchFocused {
                SearchBarV2(isActive: $searchFocused, action: handleAction(_:))
            } else {
                TopBar
            }
        }
    }
}

// MARK: - SelectedItemsSection

private extension AddItemToDocumentSheetV2 {
     var SelectedItemsSection: some View {
        VStack(spacing: 12) {
            RDButton(
                variant: multiSelectEnabled ? .red : .secondary,
                size: .sm,
                label: multiSelectEnabled ? "Deselect All" : "Select",
                fullWidth: false
            ) {
                withAnimation(Constants.Animation.snappy) {
                    multiSelectEnabled.toggle()
                    if multiSelectEnabled {
                        viewModel.deselectAll()
                    }
                }
            }
            
            if viewModel.showSelectedItems {
                SelectedItemsList
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.red, lineWidth: 4)
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
                
            if multiSelectEnabled {
                SelectedItemsRow
            }
        }
    }
    
    var SelectedItemsRow: some View {
        Button {
            if !viewModel.selectedItems.isEmpty {
                withAnimation(Constants.Animation.snappy) {
                    viewModel.showSelectedItems.toggle()
                }
            }
        } label: {
            HStack {
                Image(systemName: viewModel.showSelectedItems ? SFSymbols.chevronUp : SFSymbols.chevronDown)
                    .font(.caption)
                    .foregroundStyle(!viewModel.selectedItems.isEmpty ? .white : Color(.systemGray5))
                
                Text("\(viewModel.selectedItems.count) selected")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .bold()
                
                Spacer()
                
                RDButton(
                    variant: .secondary,
                    size: .sm,
                    leadingIcon: SFSymbols.plus,
                    iconBold: true,
                    label: "Add Selected",
                    fullWidth: false
                ) {
                    Task {
                        let success = await viewModel.addItemsToDocument()
                        if success { dismiss() }
                    }
                }
                .disabled(viewModel.selectedItems.isEmpty)
            }
            .padding(8)
            .buttonStyle(.plain)
            .background(.red)
            .cornerRadius(8)
        }
    }
    
    var SelectedItemsList: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(viewModel.selectedItems), id: \.id) { item in
                ItemListItemView(
                    item: item,
                    style: .display,
                    action: handleAction(_:)
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
                        withAnimation(Constants.Animation.snappy) {
                            searchFocused = true
                        }
                    }
                }
            }
        )
    }

    private var ItemList: some View {
        DocumentListSection(
            viewModel: documentListViewModel,
            noMoreLabel: "No More Items",
            action: handleAction(_:)
        ) { item in
            ItemListItemView(
                item: item,
                style: multiSelectEnabled ? .addToDocument : .display,
                isSelected: viewModel.isSelected(item),
                action: handleAction(_:)
            )
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
        case let sectionAction as DocumentListSectionAction:
            switch sectionAction {
            case .loadMore:
                Task { await documentListViewModel.loadMore() }
            }
        case let itemListItemAction as ItemListItemAction:
            switch itemListItemAction {
            case .navigate(let item):
                path.append(NavigationDestination.addItemToDocumentDetailView(item: item, destination: viewModel.destination))
            case .multiSelectSelection(let item):
                withAnimation(Constants.Animation.snappy) {
                    viewModel.select(item)
                }
            case .multiSelectDeselection(let item):
                withAnimation(Constants.Animation.snappy) {
                    viewModel.deselect(item)
                }
            default:
                return
            }
        default:
            print("[ERROR]: Untracked action")
        }
    }
}

private extension AddItemToDocumentSheetV2 {
    var LoadingIndicator: some View {
        ProgressView("Adding items...")
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            .shadow(radius: 10)
    }
}
