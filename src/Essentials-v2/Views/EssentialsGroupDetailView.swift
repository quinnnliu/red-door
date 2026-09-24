//
//  EssentialsGroupDetailView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/25/26.
//

import SwiftUI

struct EssentialsGroupDetailView: View {
    @State private var viewModel: EssentialsGroupDetailViewModel
    @State private var showAddItemsSheet: Bool = false
    @State private var showEditSheet: Bool = false
    @State private var itemToRemove: ItemV2? = nil
    @State private var showRemoveAlert: Bool = false
    @State private var showSelectAccessoriesSheet: Bool = false
    @State private var showRemoveAccessoriesAlert: Bool = false
    @State private var showAssignToPullListSheet: Bool = false

    let emoji: String

    init(group: EssentialsGroup, emoji: String = "⭐️") {
        viewModel = EssentialsGroupDetailViewModel(group: group)
        self.emoji = emoji
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            TopBar
                .frameHorizontalPadding()

            ScrollView {
                VStack(spacing: 16) {
                    DetailsSection

                    ItemList
                }
                .frameHorizontalPadding()
            }

            AccessoriesSection
                .frameHorizontalPadding()

            SmallCTA(type: .red, leadingIcon: SFSymbols.pencilAndListClipboard, text: "Assign to Pull List") {
                showAssignToPullListSheet = true
            }
            .frameHorizontalPadding()
        }
        .sheet(isPresented: $showEditSheet) {
            EssentialsViewFactory().makeEditEssentialsGroupSheet(group: viewModel.groupState)
        }
        .sheet(isPresented: $showAddItemsSheet) {
            AddItemToDocumentSheetV2(
                defaultFilters: [
                    "\(ItemV2.CodingKeys.location.rawValue).\(DocumentLocation.CodingKeys.status.rawValue)": LocationStatus.inStorage.rawValue,
                    ItemV2.CodingKeys.essentialGroupId.rawValue: AnyHashable(NSNull())
                ]
            ) { item in
                AddItemDocumentContext.itemToEssentialsGroup(item: item, group: viewModel.groupState)
            }
        }
        .sheet(isPresented: $showAssignToPullListSheet) {
            AddEssentialsGroupToPullListSheet(action: handleAction(_:))
        }
        .sheet(isPresented: $showSelectAccessoriesSheet) {
            SelectDocumentSheet(
                title: "Select Accessories",
                documents: viewModel.availableAccessories,
                action: { action in
                    if case let .selected(accessories) = action as? SelectDocumentSheetAction<Accessories> {
                        Task { await viewModel.setAccessories(accessories) }
                    }
                },
                refreshAction: { Task { await viewModel.fetchAvailableAccessories() } }
            )
            .task { await viewModel.fetchAvailableAccessories() }
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK") { }
        }
        .alert("Remove Accessories", isPresented: $showRemoveAccessoriesAlert) {
            Button("Remove", role: .destructive) {
                Task { await viewModel.removeAccessories() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Remove \(viewModel.accessoriesState?.displayName ?? "accessories") from \(viewModel.groupState.displayName)?")
        }
        .alert("Remove Item", isPresented: $showRemoveAlert) {
            Button("Remove", role: .destructive) {
                if let item = itemToRemove {
                    Task { await viewModel.removeItem(item) }
                }
            }
            Button("Cancel", role: .cancel) {
                itemToRemove = nil
            }
        } message: {
            if let item = itemToRemove {
                Text("Remove \(item.displayName) from \(viewModel.groupState.displayName)?")
            }
        }
        .onAppear {
            viewModel.startListening()
        }
        .toolbar(.hidden)
        .frameTop()
    }
}

// MARK: - Top Bar

private extension EssentialsGroupDetailView {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton()
            },
            header: {
                Text("Essentials Group")
                    .bold()
                    .foregroundStyle(.red)
            },
            trailingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.pencil) {
                    showEditSheet = true
                }
                .clipShape(Circle())
                .disabled(!viewModel.groupState.location.status.isAvailable)
            }
        )
    }
}

// MARK: - Information
private extension EssentialsGroupDetailView {
    var DetailsSection: some View {
        VStack {
            Text("\(emoji) \(viewModel.groupState.displayName)")
                .font(.headline)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            DetailsText(label: "Location", text: viewModel.groupState.location.status.displayTitle)
            
            ForEach(Array(getCategoryCounts()), id: \.key) { key, value in
                DetailsText(label: key, text: String(value))
            }
        }
    }
    
    func DetailsText(label: String, text: String) -> some View {
        HStack {
            Text("\(label):")
            
            Text(text)
        }
    }
    
    func getCategoryCounts() -> [String: Int] {
        var categoryCounts: [String: Int] = [:]
        viewModel.items.forEach {
            let key = $0.type.rawValue
            categoryCounts[key, default: 0] += 1
        }
        return categoryCounts
    }
}

// MARK: - Item List

private extension EssentialsGroupDetailView {
    var ItemList: some View {
        VStack {
            HStack {
                Text("Items")
                    .foregroundStyle(.red)
                    .font(.headline)
                
                Spacer()
                
                SmallCTA(type: .red, leadingIcon: SFSymbols.plus, text: "Add Items") {
                    showAddItemsSheet = true
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.items, id: \.id) { item in
                    ItemDocumentListItemView(item: item, style: .essentialsGroup, action: handleAction(_:))
                }
            }
        }
    }
}

private extension EssentialsGroupDetailView {
    func handleAction(_ actionArgument: Any?) {
        switch actionArgument {
        case let itemListItemAction as ItemDocumentListItemAction:
            switch itemListItemAction {
            case .removeItem(let item):
                itemToRemove = item
                showRemoveAlert = true
            default:
                return
            }
        case let pullListAction as PullListListItemAction:
            switch pullListAction {
            case .assignEssentialsToList(let list):
                Task { await viewModel.assignToPullList(list) }
            default:
                return
            }
        default:
            return
        }
    }
}

// MARK: - Accessories Section

private extension EssentialsGroupDetailView {
    var AccessoriesSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Accessories")
                    .foregroundStyle(.red)
                    .font(.headline)

                Spacer()

                if viewModel.accessoriesState == nil {
                    SmallCTA(type: .red, leadingIcon: SFSymbols.plus, text: "Add Accessories") {
                        showSelectAccessoriesSheet = true
                    }
                }
            }

            if let accessories = viewModel.accessoriesState {
                AccessoriesListItemView(accessories: accessories, onRemove: {
                    showRemoveAccessoriesAlert = true
                })
            }
        }
    }
}
