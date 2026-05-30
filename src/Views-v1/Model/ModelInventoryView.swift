import SwiftUI
import CodeScanner

struct ModelInventoryView: View {
    @State private var viewModel = DocumentsListViewModel(.model)
    @Binding var path: NavigationPath

    // Filter Variables

    @State private var searchText: String = ""
    @State private var selectedType: ModelType?

    // View Modifier Variables

    @State private var isLoadingModels: Bool = false
    @State private var searchFocused: Bool = false
    @FocusState private var searchTextFocused: Bool

    @State private var showCreateModelCover: Bool = false
    @State private var showScannerSheet: Bool = false
    @State private var scannedItemId: String? = nil

    // MARK: Body

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 12) {
                if searchFocused {
                    SearchBar()
                } else {
                    TopBar()
                }

                ModelInventoryFilterView(selectedType: $selectedType)

                InventoryList()

                Spacer()
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
            .rootNavigationDestinations(path: $path)
            .fullScreenCover(isPresented: $showCreateModelCover) {
                CreateModelView()
            }
            .sheet(isPresented: $showScannerSheet) {
                ItemScannerView(scannedItemId: $scannedItemId)
            }
            .onChange(of: scannedItemId) { _, newValue in
                guard let newValue else { return }
                handleScannedItemId(itemId: newValue)
            }
        }
    }

    // MARK: Top Bar

    @ViewBuilder
    private func TopBar() -> some View {
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
                    await fetchModels(initial: true, searchText: searchText, modelType: selectedType)
                }
            }
        )
    }

    // MARK: Inventory List

    @ViewBuilder 
    private func InventoryList() -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.documentsArray.compactMap { $0 as? Model }, id: \.self) { model in
                    NavigationLink(value: model) {
                        ModelListItemView(model: model)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        if model == viewModel.documentsArray.last as? Model {
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
        .refreshable {
            Task {
                if !isLoadingModels {
                    await fetchModels(initial: true, searchText: nil, modelType: selectedType)
                }
            }
        }
    }

    // MARK: Fetch Models (Using the Abstracted ViewModel)

    private func fetchModels(initial isInitial: Bool, searchText: String?, modelType: ModelType?) async {
        var filters: [String: Any] = [:]

        if let modelType {
            filters.updateValue(modelType.rawValue, forKey: "type")
        }

        if let searchText {
            filters.updateValue(searchText.lowercased(), forKey: "nameLowercased")
        }

        isLoadingModels = true
        if isInitial {
            await viewModel.fetchInitialDocuments(filters: filters)
        } else {
            await viewModel.fetchMoreDocuments(filters: filters)
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

    private func handleScannedItemId(itemId: String) {
        Task {
            let item = try await Item.getItem(itemId: itemId)
            path.append(item)
        }
        scannedItemId = nil
    }
}

#Preview {
    ModelInventoryView(path: .constant(.init()))
}
