//
//  EditRoomSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/31/25.
//

import SwiftUI

struct EditRoomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var roomViewModel: RoomViewModel

    @State private var showRoomNameSheet: Bool = false
    @State private var editingRoom: Room

    init(roomViewModel: Binding<RoomViewModel>) {
        _roomViewModel = roomViewModel
        editingRoom = roomViewModel.wrappedValue.selectedRoom
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 16) {
            TextField("Room Name", text: $editingRoom.roomName)
                .submitLabel(.done)

            HStack(spacing: 0) {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }

                Spacer()

                Button {
                    roomViewModel.updateRoom(newRoom: editingRoom)
                    dismiss()
                } label: {
                    Text("Save")
                        .fontWeight(.semibold)
                }
            }
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameVerticalPadding()
        .presentationDetents([.fraction(0.125)])
    }
}