//
//  RoomAddItemsSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 2/13/25.
//

import SwiftUI

struct RoomAddItemsSheet: View {
    // MARK: Environment Variables

    @Environment(\.dismiss) private var dismiss

    // MARK: View Parameters

    @State private var inventoryViewModel: DocumentsListViewModel = .init(.model)
    @Binding var roomViewModel: RoomViewModel
    @Binding var showSheet: Bool

    // MARK: init()

    init(roomViewModel: Binding<RoomViewModel>, showSheet: Binding<Bool>) {
        _roomViewModel = roomViewModel
        _showSheet = showSheet
    }

    // MARK: Filter Variables

    @State private var searchText: String = ""
    @State private var selectedType: ModelType?

    // MARK: State Variables

    @State var path: NavigationPath = .init()
    @State private var searchFocused: Bool = false
    @FocusState var searchTextFocused: Bool
    @State private var isLoadingModels: Bool = false

    // MARK: Body

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 6) {

                DragIndicator()

                VStack(spacing: 12) {
                    if searchFocused {
                        SearchBar()
                    } else {
                        TopBar()
                    }

                    ModelInventoryFilterView(selectedType: $selectedType)

                    InventoryList()
                }
            }
            .frameTop()
            .frameHorizontalPadding()
            .onAppear {
                emptyQuerySearch()
            }
            .onChange(of: path) {
                searchFocused = false
            }
            .onChange(of: selectedType) {
                searchText = ""
                emptyQuerySearch()
            }
            .onChange(of: searchText) {
                if searchText.isEmpty {
                    emptyQuerySearch()
                }
            }
            .navigationDestination(for: Model.self) { model in
                RoomModelView(model: model, roomViewModel: $roomViewModel)
            }
        }
    }

    // MARK: Top Bar

    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(
            leadingView: {
                Text("Available Inventory")
                    .font(.system(.title2, design: .default))
                    .bold()
                    .foregroundStyle(.red)
            },
            header: {
                EmptyView()
            },
            trailingView: {
                if !searchFocused {
                    RDButton(variant: .outline, size: .icon, leadingIcon: "magnifyingglass", iconBold: true, fullWidth: false) {
                        searchFocused = true
                        searchTextFocused = true
                    }
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
                    await fetchModels(initial: true, searchText: searchText, modelType: selectedType)
                }
            }
        )
    }

    // MARK: InventoryList

    @ViewBuilder 
    private func InventoryList() -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(inventoryViewModel.documentsArray.compactMap { $0 as? Model }, id: \.self) { model in
                    NavigationLink(value: model) {
                        ModelListItemView(model: model)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        if model == inventoryViewModel.documentsArray.last as? Model {
                            Task {
                                await fetchModels(initial: false, searchText: searchText.isEmpty ? nil : searchText, modelType: selectedType)
                            }
                        }
                    }
                }

                if isLoadingModels {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
    }

    // MARK: Fetch Models (Using the Abstracted ViewModel)

    @MainActor
    private func fetchModels(initial isInitial: Bool, searchText: String?, modelType: ModelType?) async {
        var filters: [String: Any] = [:]
        filters["itemsAvailable"] = true

        if let modelType {
            filters.updateValue(modelType.rawValue, forKey: "type")
        }

        if let searchText {
            filters.updateValue(searchText.lowercased(), forKey: "nameLowercased")
        }

        isLoadingModels = true
        if isInitial {
            await inventoryViewModel.fetchInitialDocuments(filters: filters)
        } else {
            await inventoryViewModel.fetchMoreDocuments(filters: filters)
        }
        isLoadingModels = false
    }

    // MARK: Handlers/Helpers

    private func emptyQuerySearch() {
        if !isLoadingModels {
            isLoadingModels = true
            Task {
                await fetchModels(initial: true, searchText: nil, modelType: selectedType)
            }
            isLoadingModels = false
        }
    }
}

// #Preview {
//    RoomAddItemsSheet(room: Room.MOCK_DATA[0], showSheet: .constant(true))
// }
