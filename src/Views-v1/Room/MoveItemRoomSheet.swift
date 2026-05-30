//
//  MoveItemRoomSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/8/25.
//

import SwiftUI

struct MoveItemRoomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var roomViewModel: RoomViewModel
    @Binding var alertMessage: String
    @Binding var showAlert: Bool
    let parentList: RDList
    let item: Item
    let rooms: [Room]

    var body: some View {
        VStack(spacing: 16) {
            DragIndicator()

            (
                Text("Other Rooms: ")
                +
                Text(parentList.address.getStreetAddress() ?? parentList.address.formattedAddress)
                    .bold()
                    .foregroundColor(.red)
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(rooms, id: \.self) { otherRoom in
                    if otherRoom.id != roomViewModel.selectedRoom.id {
                        Button {
                            Task {
                                let added = await roomViewModel.moveItemToNewRoom(item: item, newRoomId: otherRoom.id)
                                dismiss()
                                if added {
                                    showAlert = true
                                    alertMessage = "Item has been moved to \(otherRoom.roomName)."
                                } else {
                                    showAlert = true
                                    alertMessage = "Failed to move item to \(otherRoom.roomName)."
                                }
                            }
                        } label: {
                            Text(otherRoom.roomName)
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
        .frameTop()
        .frameHorizontalPadding()
        .frameVerticalPadding()
        .presentationDetents([.medium])
    }
}