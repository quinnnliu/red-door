//
//  MoveItemRoomSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/5/26.
//

import SwiftUI

struct MoveItemV2RoomSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State var viewModel: MoveItemV2RoomSheetViewModel
    
    let item: ItemV2
    let room: RoomV2
    var rooms: [RoomV2]
    let list: PullListV2
    
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""
    
    init(room: RoomV2, rooms: [RoomV2], item: ItemV2, list: PullListV2) {
        self.viewModel = MoveItemV2RoomSheetViewModel(room: room)
        self.room = room
        self.item = item
        self.rooms = rooms
        self.list = list
    }
    
    var body: some View {
        VStack(spacing: 16) {
            DragIndicator()
            
            (
                Text("Other Rooms: ")
                +
                Text(list.address.getStreetAddress() ?? list.address.formattedAddress)
                    .bold()
                    .foregroundColor(.red)
            )
            
            ScrollView {
                LazyVStack {
                    ForEach(rooms) { otherRoom in
                        if otherRoom.id != room.id {
                            Button {
                                Task {
                                    let added = await viewModel.moveItemToNewRoom(item: item)
                                    dismiss()
                                    if added {
                                        showAlert = true
                                        alertMessage = "Item has been moved to \(otherRoom.displayName)."
                                    } else {
                                        showAlert = true
                                        alertMessage = "Failed to move item to \(otherRoom.displayName)."
                                    }
                                }
                            } label: {
                                Text(otherRoom.displayName)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                                    .foregroundColor(.primary)
                                    .bold()
                            }
                            .buttonStyle(.plain)
                        }
                    }

                }
            }
            
//            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
//            }
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameVerticalPadding()
        .presentationDetents([.medium])
    }
}
