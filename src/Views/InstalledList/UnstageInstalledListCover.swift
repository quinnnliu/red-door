//
//  UnstageInstalledListCover.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/13/25.
//

import SwiftUI

struct UnstageInstalledListCover: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator.self) private var coordinator: NavigationCoordinator
    @Binding var viewModel: InstalledListViewModel

    @State private var unstagedItems: [Item] = []
    @State private var stagedItems: [Item] = []
    @State private var modelsById: [String: Model] = [:]

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @State private var showUnstageSheet: Bool = false
    @State private var selectedItemAndModel: (Item, Model)? = nil

    init(viewModel: Binding<InstalledListViewModel>) {
        _viewModel = viewModel
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 16) {
            TopBar()

            ScrollView {
                LazyVStack(spacing: 12) {
                    StagedItemList()
                    
                    UnstagedItemList()
                }
            }
            .refreshable {
                stagedItems = []
                unstagedItems = []
                await loadItems()
                await loadModels()
            }
            
            Spacer()

            Footer()
        }
        .sheet(isPresented: $showUnstageSheet) {
            if let selectedItemAndModel {
                UnstageItemSheet(selectedItemAndModel, stagedItems: $stagedItems, unstagedItems: $unstagedItems)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertMessage), message: nil, dismissButton: .default(Text("OK")))
        }
        .frameTop()
        .frameHorizontalPadding()
        .task {
            await loadItems()
            await loadModels()
        }
    }

    // MARK: Top Bar

    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(
            leadingView: { ExitButton() },
            header: {
                (
                    Text("Unstaging: ")
                        .foregroundColor(.red)
                        .bold()
                    +
                    Text(viewModel.selectedList.address.getStreetAddress() ?? "")
                )
            },
            trailingView: { 
                RDButton(variant: .red, size: .icon, leadingIcon: "arrow.counterclockwise", fullWidth: false) {
                    Task {
                        stagedItems = []
                        unstagedItems = []
                        await loadItems()
                        await loadModels()
                    }
                }
                .clipShape(Circle())
            }
        )
    }

    // MARK: Exit Button

    @ViewBuilder
    private func ExitButton() -> some View {
        RDButton(variant: .red, size: .icon, leadingIcon: "xmark", iconBold: true, fullWidth: false) {
            dismiss()
        }
    }

    // MARK: Unstaged Item List

    @ViewBuilder
    private func UnstagedItemList() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Text("Items in Warehouse")
                    .font(.headline)
                    .foregroundColor(.red)

                Spacer()

                Text("(\(unstagedItems.count))")
                    .foregroundColor(.secondary)
            }
            
            LazyVStack {
                ForEach(unstagedItems, id: \.self) { item in
                    ItemListItem(item)
                }
            }
            .padding(4)

        }
    }

    // MARK: Staged Item List
    @ViewBuilder
    private func StagedItemList() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {    
                Text("Staged Items")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("(\(stagedItems.count))")
                    .foregroundColor(.secondary)
            }

            LazyVStack(spacing: 12) {
                ForEach(stagedItems, id: \.self) { item in
                    ItemListItem(item)
                }
            }
            .padding(4)
        }
    }
    
    // MARK: Item List Item
    @ViewBuilder
    private func ItemListItem(_ item: Item) -> some View {
        if let model = modelsById[item.modelId] {
            HStack(spacing: 8) {
                ItemModelImage(item: item, model: model)

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .foregroundColor(.primary)
                        .bold()
                
                    HStack(spacing: 4) {
                        Image(systemName: Model.typeMap[model.type] ?? "nosign")
                        
                        Text("•")
                        
                        Image(systemName: SFSymbols.circleFill)
                            .foregroundColor(Model.colorMap[model.primaryColor])
                        
                        Text("•")

                        Text(model.primaryMaterial)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                if item.isAvailable {
                    RDButton(variant: .default, size: .icon, leadingIcon: SFSymbols.arrowUturnBackward, fullWidth: false) {
                        Task {
                            let result = await ItemViewModel(selectedItem: item).revertItemUnstage(listId: item.listId)
                            unstagedItems.removeAll { $0.id == result.id }
                            stagedItems.append(result)
                            alertMessage = "Item status restored to unavailable."
                            showAlert = true
                        }
                    }
                } else {
                    RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.shippingbox, fullWidth: false) {
                        selectedItemAndModel = (item, model)
                        showUnstageSheet = true
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray5))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(item.attention ? Color.yellow : Color(.systemGray3), lineWidth: 3)
            )
        }
    }


    // MARK: Footer

    @ViewBuilder
    private func Footer() -> some View {
        if stagedItems.isEmpty {
            HStack(spacing: 0) {
                RDButton(variant: .red, size: .default, leadingIcon: SFSymbols.checkmarkSquareFill, label: "Set List as Unstaged", fullWidth: true) {
                    Task {
                        await viewModel.setListAsUnstaged()
                        coordinator.resetSelectedPath()
                    }
                }
            }
        }
    }

    // MARK: Load Items

    @MainActor
    private func loadItems() async {
        for room in viewModel.rooms {
            for itemId in room.itemModelIdMap.keys {
                do {
                    let item = try await Item.getItem(itemId: itemId)
                    if !item.isAvailable {
                        stagedItems.append(item)
                    } else {
                        unstagedItems.append(item)
                    }
                } catch {
                    print("Error loading item \(itemId): \(error)")
                }
            }
        }
    }

    // MARK: Load Models

    @MainActor
    private func loadModels() async {
        for item in unstagedItems + stagedItems {
            if !modelsById.keys.contains(item.modelId) {
                do {
                    let model = try await Model.getModel(modelId: item.modelId)
                    modelsById[item.modelId] = model
                } catch {
                    print("Error loading model \(item.modelId): \(error)")
                }
            }
        }
    }
}
