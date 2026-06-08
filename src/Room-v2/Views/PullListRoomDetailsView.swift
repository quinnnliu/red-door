//
//  PullListRoomDetailsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import SwiftUI
import CachedAsyncImage

struct PullListRoomDetailsView: View {
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
    
    // MARK: Top Bar
    
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
    
    // MARK: Room Details Menu
    
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
            RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.ellipsis, iconBold: true, fullWidth: false, action: {})
                .clipShape(Circle())
        }
        .tint(.red)
    }
    
    // MARK: Room Item List
    
    private var RoomItemList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.items, id: \.self) { item in
                    NavigationLink(value: NavigationDestination.pullListItemDetailView(item: item, room: viewModel.roomState)) {
                        RoomItemListItemView(item: item)
                    }
                }
            }
            .padding(8)
        }
    }
    
    // MARK: Room Item List Item
    
    @ViewBuilder
    private func RoomItemListItemView(item: ItemV2) -> some View {
        HStack(alignment: .center, spacing: 8) {
            if item.primaryImage.imageExists {
                ItemImage(image: item.primaryImage)
            } else {
                Color.gray
                    .overlay(Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                        .foregroundColor(.white))
            }
            
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
    
    // MARK: Item Image
    
    @ViewBuilder
    private func ItemImage(image: RDImage, size: CGFloat = 48) -> some View {
        if let imageURL = image.imageURL {
            CachedAsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(size)
                    .cornerRadius(4)
            } placeholder: {
                RoundedRectangle(cornerRadius: 4)
                    .foregroundColor(Color(.systemGray4))
                    .frame(size)
                    .overlay(Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                        .foregroundColor(.secondary))
            }
        }
    }
}
