//
//  StagingRoomDetailsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/4/25.
//

import CachedAsyncImage
import SwiftUI

struct StagingRoomDetailsView: View {
    // MARK: init Variables
    
    private var parentList: RDList
    private var rooms: [Room]
    @Binding var roomViewModel: RoomViewModel

    init(parentList: RDList, rooms: [Room], roomViewModel: Binding<RoomViewModel>) {
        self.parentList = parentList
        self.rooms = rooms
        _roomViewModel = roomViewModel
    }

    // MARK: State Variables

    @State private var showAddItemsSheet: Bool = false
    @State private var showEditRoomSheet: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var itemToMove: Item? = nil

    // MARK: Body
    
    var body: some View {
        VStack(spacing: 16) {
            TopBar()

            HStack(spacing: 0) {
                SmallCTA(type: .secondary, leadingIcon: SFSymbols.arrowCounterclockwise, text: "Refresh") { 
                    Task {
                        await roomViewModel.loadItemsAndModels()
                    }
                }
                
                Spacer()

                SmallCTA(type: .red, leadingIcon: SFSymbols.plus, text: "Add Items") { 
                    showAddItemsSheet = true
                }
            }

            RoomItemList()
        }
        .sheet(isPresented: $showAddItemsSheet) {
            RoomAddItemsSheet(roomViewModel: $roomViewModel, showSheet: $showAddItemsSheet)
        }
        .sheet(isPresented: $showEditRoomSheet) {
            EditRoomSheet(roomViewModel: $roomViewModel)
        }
        .task {
            if !roomViewModel.items.isEmpty {
                await roomViewModel.loadItemsAndModels()
            }
        }
        .onChange(of: roomViewModel.selectedRoom.itemModelIdMap) { // TODO: not auto-reload?
            Task {
                await roomViewModel.loadItemsAndModels()
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                alertMessage = ""
            }
        }
        .sheet(item: $itemToMove) { item in
            MoveItemRoomSheet(roomViewModel: $roomViewModel, alertMessage: $alertMessage, showAlert: $showAlert, parentList: parentList, item: item, rooms: rooms)
        }
        .toolbar(.hidden)
        .frameTop()
        .frameHorizontalPadding()
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: Top Bar

    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(
            leadingView: {
                BackButton()
            }, header: {
                (
                    Text("Room: ")
                        .foregroundColor(.red)
                        .bold()
                    +   
                    Text(roomViewModel.selectedRoom.roomName)
                        .bold()
                )
            }, trailingView: {
                Spacer().frame(32)
            }
        )
    }

    // MARK: Room Item List

    @ViewBuilder
    private func RoomItemList() -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(roomViewModel.items, id: \.self) { item in
                    NavigationLink(destination: StagingRoomItemView(roomViewModel: $roomViewModel, item: item, model: roomViewModel.getModelForItem(item), parentList: parentList, rooms: rooms)) {
                        RoomItemListItemView(item: item, model: roomViewModel.getModelForItem(item))
                    }
                }
            }
            .padding(8)
        }
        .refreshable {
            await roomViewModel.loadItemsAndModels()
        }
    }

    // MARK: Room Item List Item

    @ViewBuilder
    private func RoomItemListItemView(item: Item, model: Model?) -> some View {
        HStack(alignment: .center, spacing: 8) {
            if let image = item.image {
                ItemImage(image: image)
            } else if let image = model?.primaryImage {
                ItemImage(image: image)
            } else {
                Color.gray
                    .overlay(Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                        .foregroundColor(.white))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(model?.name ?? "No Model Name")
                    .foregroundColor(.primary)
                    .bold()
                
                HStack(spacing: 4) {
                    Image(systemName: Model.typeMap[model?.type ?? ""] ?? "nosign")
                    
                    Text("•")
                    
                    Image(systemName: SFSymbols.circleFill)
                        .foregroundColor(Model.colorMap[model?.primaryColor ?? ""] ?? .black)
                    
                    Text("•")

                    Text(model?.primaryMaterial ?? "No Material")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer() 

            RDButton(variant: .default, size: .icon, leadingIcon: SFSymbols.arrowUturnBackward, fullWidth: false) {
                itemToMove = item
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
