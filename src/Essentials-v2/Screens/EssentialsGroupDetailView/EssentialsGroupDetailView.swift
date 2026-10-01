//
//  EssentialsGroupDetailView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/25/26.
//

import SwiftUI

struct EssentialsGroupDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EssentialsGroupDetailViewModel
    @State private var showAddItemsSheet: Bool = false
    @State private var showEditSheet: Bool = false
    @State private var itemToRemove: ItemV2? = nil
    @State private var showRemoveAlert: Bool = false
    @State private var showSelectAccessoriesSheet: Bool = false
    @State private var showRemoveAccessoriesAlert: Bool = false
    @State private var showAssignToPullListSheet: Bool = false

    init(group: EssentialsGroup) {
        viewModel = EssentialsGroupDetailViewModel(group: group)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            TopBar
            
            AccessoriesSection

            LocationRow
            
            ItemList
                
            RDButton(
                variant: .red,
                size: .default,
                leadingIcon: SFSymbols.pencilAndListClipboard,
                label: "Assign to Pull List",
                fullWidth: true
            ) {
                    showAssignToPullListSheet = true
            }
            .disabled(!viewModel.groupState.location.status.isAvailable)
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .sheet(isPresented: $showEditSheet) {
            EssentialsViewFactory().makeEditEssentialsGroupSheet(group: viewModel.groupState, onDelete: { dismiss() })
        }
        .sheet(isPresented: $showAddItemsSheet) {
            AddItemToDocumentSheetV2(
                destination: .essentialsGroup(viewModel.groupState),
                defaultFilters: [
                    "\(ItemV2.CodingKeys.location.rawValue).\(DocumentLocation.CodingKeys.status.rawValue)": LocationStatus.inStorage.rawValue,
                    ItemV2.CodingKeys.essentialGroupId.rawValue: AnyHashable(NSNull())
                ]
            )
        }
        .sheet(isPresented: $showAssignToPullListSheet) {
            AddEssentialsGroupToPullListSheet(action: handleAction(_:))
        }
        .sheet(isPresented: $showSelectAccessoriesSheet) {
            SelectAccessoriesSheet(action: handleAction(_:))
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
                (
                    Text("Essentials: ")
                        .bold()
                        .foregroundStyle(.red)
                    +
                    Text("\(viewModel.groupState.emoji) \(viewModel.groupState.displayName)")
                        .bold()
                )
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

// MARK - LocationRow
private extension EssentialsGroupDetailView {
    var LocationRow: some View {
        HStack {
            Text("Location")
                .bold()
                .foregroundStyle(.red)
            
            Spacer()
            
            SmallCTA(
                isButton: false,
                type: viewModel.groupState.location.status.isAvailable ? .outline: .red,
                size: .small,
                leadingIcon: viewModel.groupState.location.status.icon,
                text: viewModel.groupState.location.status.displayTitle,
                semibold: false
            )
        }
    }
}

// MARK: - Item List

private extension EssentialsGroupDetailView {
    var ItemList: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text("Items")
                        .foregroundStyle(.red)
                        .font(.headline)
                    
                    Spacer()
                    
                    SmallCTA(type: .red, leadingIcon: SFSymbols.plus, text: "Add Items") {
                        showAddItemsSheet = true
                    }
                    .disabled(!viewModel.groupState.location.status.isAvailable)
                }
                
                LazyVStack(spacing: 8) {
                    ForEach(groupedItems, id: \.type) { group in
                        ExpandableSectionView(
                            style: .essentialsItemTypeGroup(type: group.type, count: group.items.count),
                            isExpanded: false
                        ) {
                            VStack(spacing: 8) {
                                ForEach(group.items, id: \.id) { item in
                                    ItemListItemView(item: item, style: .essentialsGroup, action: handleAction(_:))
                                }
                            }
                        }
                    }
                }
            }

        }
    }

    var groupedItems: [(type: ItemType, items: [ItemV2])] {
        ItemType.allCases.compactMap { type in
            let items = viewModel.items.filter { $0.type == type }
            return items.isEmpty ? nil : (type, items)
        }
    }
}

private extension EssentialsGroupDetailView {
    func handleAction(_ actionArgument: Any?) {
        switch actionArgument {
        case let itemListItemAction as ItemListItemAction:
            switch itemListItemAction {
            case .removeItem(let item):
                itemToRemove = item
                showRemoveAlert = true
            default:
                return
            }
        case let accessoriesAction as AccessoriesListItemAction:
            switch accessoriesAction {
            case .select(let accessories):
                Task { await viewModel.setAccessories(accessories) }
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
                    .disabled(!viewModel.groupState.location.status.isAvailable)
                }
            }

            if let accessories = viewModel.accessoriesState {
                AccessoriesListItemView(accessories, style: .navigate(accessories)) {
                    showRemoveAccessoriesAlert = true
                }
            }
        }
    }
}
