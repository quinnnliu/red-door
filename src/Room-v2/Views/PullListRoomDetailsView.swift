//
//  PullListRoomDetailsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import SwiftUI
import CachedAsyncImage

struct PullListRoomDetailsView: View {
    typealias ImageEditorAction = PrimaryImageEditor.ImageEditorAction
    
    @Environment(NavigationCoordinator.self) var coordinator
    @State var viewModel: PullListRoomDetailsViewModel
    @State var itemToRemove: ItemV2? = nil

    init(items: [ItemV2], room: RoomV2) {
        self.viewModel = PullListRoomDetailsViewModel(room: room, items: items)
    }
    
    // MARK: State Variables
    @State private var showAddItemsSheet: Bool = false
    @State private var showEditRoomSheet: Bool = false
    @State private var showRemoveItemAlert: Bool = false
    
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
            RoomAddItemsSheetV2(room: viewModel.roomState)
        }
        .sheet(isPresented: $showEditRoomSheet) {
            EditRoomV2Sheet(currentRoomName: viewModel.roomState.displayName) { newRoomName in
                Task {
                    await viewModel.renameRoom(roomId: viewModel.roomState.id, newRoomName: newRoomName)
                }
            }
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Remove Item", isPresented: $showRemoveItemAlert) {
            Button("Remove", role: .destructive) {
                if let item = itemToRemove {
                    Task {
                        await viewModel.removeItemFromRoom(item: item)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                itemToRemove = nil
                showRemoveItemAlert = false
            }
        } message: {
            Text("Are you sure you want to remove this item from \(viewModel.roomState.displayName)?")
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
            ItemListItemImage(item.primaryImage)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .foregroundColor(.primary)
                    .bold()
                
                HStack(spacing: 4) {
                    Image(systemName: item.type.icon)
                    
                    Text("•")
                    
                    Image(systemName: SFSymbols.circleFill)
                        .foregroundColor(item.color.color)
                    
                    Text("•")
                    
                    Text(item.material.title)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.trash, fullWidth: false) {
                itemToRemove = item
                showRemoveItemAlert = true
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
