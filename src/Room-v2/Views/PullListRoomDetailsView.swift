//
//  PullListRoomDetailsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import SwiftUI
import CachedAsyncImage

struct PullListRoomDetailsView: View {
    
    @State var viewModel: PullListRoomDetailsViewModel
    @State var itemToRemove: ItemV2? = nil

    init(items: [ItemV2], room: RoomV2) {
        self.viewModel = PullListRoomDetailsViewModel(room: room, items: items)
    }
    
    // MARK: State Variables
    @State private var showAddItemsSheet: Bool = false
    @State private var showEditRoomSheet: Bool = false
    @State private var showSelectWarehouseSheet: Bool = false
    
    // MARK: Body
    
    var body: some View {
        VStack(spacing: 16) {
            TopBar
                .frameHorizontalPadding()
            
            ScrollView {
                VStack(spacing: 16) {
                    RoomImages
                    
                    HStack(spacing: 0) {
                        SmallCTA(type: .secondary, leadingIcon: SFSymbols.arrowCounterclockwise, text: "Refresh") {
                            viewModel.refreshRoom()
                        }
                        
                        Spacer()
                        
                        SmallCTA(type: .red, leadingIcon: SFSymbols.plus, text: "Add Items") {
                            showAddItemsSheet = true
                        }
                    }
                    
                    RoomItemList
                }
                .frameHorizontalPadding()
            }
            
        }
        .sheet(isPresented: $showAddItemsSheet) {
            AddItemsToRoomSheet
        }
        .sheet(isPresented: $showEditRoomSheet) {
            EditRoomSheet
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .sheet(isPresented: $showSelectWarehouseSheet) {
            SelectDocumentSheet(
                title: "Select Storage Location",
                documents: viewModel.availableWarehouses,
                action: { action in
                    if let warehouseAction = action as? SelectDocumentSheetAction<WarehouseV2>,
                       case .selected(let warehouse) = warehouseAction,
                       let item = itemToRemove {
                        Task {
                            await viewModel.removeItemToWarehouse(item: item, warehouse: warehouse)
                            itemToRemove = nil
                        }
                    }
                },
                refreshAction: { Task { await viewModel.fetchAvailableWarehouses() } }
            )
            .task { await viewModel.fetchAvailableWarehouses() }
        }
        .onAppear {
            viewModel.startListening()
        }
        .toolbar(.hidden)
        .frameTop()
        .frameHorizontalPadding()
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - Top Bar
    
    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton()
            }, header: {
                (
                    Text("Room: ")
                        .foregroundColor(.red)
                        .bold()
                    +
                    Text(viewModel.roomState.displayName)
                        .bold()
                )
            }, trailingView: {
                RoomDetailsMenu
            }
        )
    }
    
    // MARK: - Room Images
    private var RoomImages: some View {
        HStack(spacing: 8) {
            VStack(spacing: 8) {
                Text("Before")
                    .font(.caption2)
                PrimaryImageEditor(image: viewModel.roomState.beforeImage) { result in
                    handleImageAction(result, isBefore: true)
                }
            }
            VStack(spacing: 8) {
                Text("After")
                    .font(.caption2)
                PrimaryImageEditor(image: viewModel.roomState.afterImage) { result in
                    handleImageAction(result, isBefore: false)
                }
            }
        }
    }
    
    // MARK: - Room Details Menu
    
    private var RoomDetailsMenu: some View {
        Menu {
            Button("Edit Room Name", systemImage: "pencil") {
                showEditRoomSheet = true
            }
            
            Button("Delete Room", systemImage: SFSymbols.trash) {
                    // Task {
                    // await roomViewModel.deleteRoom()
                    // }
            }
        } label: {
            RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.ellipsis, iconBold: true, fullWidth: false) { }
                .clipShape(Circle())
        }
        .tint(.red)
    }
    
    // MARK: - Room Item List
    
    private var RoomItemList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.items, id: \.self) { item in
                NavigationLink(value: NavigationDestination.pullListItemDetailView(item: item, room: viewModel.roomState)) {
                    RoomItemListItemView(item: item)
                }
            }
        }
    }
    
    // MARK: - Room Item List Item
    
    @ViewBuilder
    private func RoomItemListItemView(item: ItemV2) -> some View {
        HStack(alignment: .center, spacing: 8) {
            ThumbnailImageView(item.primaryImage)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .foregroundColor(.primary)
                    .bold()
                
                HStack(spacing: 4) {
                    Image(systemName: item.type.icon ?? SFSymbols.ellipsis)
                    Text("•")
                    Text(item.material.title)
                    if let color = item.color.color {
                        Text("•")
                        Image(systemName: SFSymbols.circleFill)
                            .foregroundColor(color)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.trash, fullWidth: false) {
                itemToRemove = item
                if item.essentialGroupId != nil {
                    Task {
                        await viewModel.moveItemToUnassigned(item: item)
                        itemToRemove = nil
                    }
                } else {
                    showSelectWarehouseSheet = true
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
    
    private func handleImageAction(_ actionArgument: Any?, isBefore: Bool) {
        guard let action = actionArgument else { return }
        switch action {
        case let imageAction as ImageEditorAction:
            if case .newImage(let image) = imageAction {
                Task {
                    await viewModel.updateRoomImage(image, isBefore: isBefore)
                }
            } else if case .deleteImage(let deletedImage) = imageAction {
                Task {
                    await viewModel.updateRoomImage(deletedImage, isBefore: isBefore)
                }
            }
        default:
            print("[ERROR] Unrtacked Action in PullListRoomDetailsView: \(action)")
        }
    }
}

// MARK: - AddItemsToRoomSheet
private extension PullListRoomDetailsView {
    var AddItemsToRoomSheet: some View {
        AddItemToDocumentSheetV2(
            destination: .room(viewModel.roomState),
            defaultFilters: [
                "\(ItemV2.CodingKeys.location.rawValue).\(DocumentLocation.CodingKeys.status.rawValue)": LocationStatus.inStorage.rawValue,
                ItemV2.CodingKeys.essentialGroupId.rawValue: NSNull() as AnyHashable
            ]
        )
    }
}

// MARK: - EditRoomSheet
private extension PullListRoomDetailsView {
    var EditRoomSheet: some View {
        EditRoomV2Sheet(currentRoomName: viewModel.roomState.displayName) { newRoomName in
            Task {
                await viewModel.renameRoom(roomId: viewModel.roomState.id, newRoomName: newRoomName)
            }
        }
    }
}
