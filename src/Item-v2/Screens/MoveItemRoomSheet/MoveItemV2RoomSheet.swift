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
    
    init(room: RoomV2, item: ItemV2) {
        self.viewModel = MoveItemV2RoomSheetViewModel(item: item, room: room)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            DragIndicator()
            
            Text("Other Rooms")
                .font(.headline)
                .foregroundStyle(.red)
            
            if viewModel.rooms.isEmpty {
                ProgressView()
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.rooms) { otherRoom in
                            if otherRoom.id != viewModel.room.id {
                                Button {
                                    Task {
                                        await viewModel.moveItemToNewRoom(newRoom: otherRoom)
                                        viewModel.alertMessage = "Added \(viewModel.item.displayName) to \(otherRoom.displayName)"
                                        viewModel.showAlert = true
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
            }
        }
        .frameTop()
        .frameHorizontalPadding()
        .presentationDetents([.medium])
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("Ok") { }
        }
        .task {
            await viewModel.fetchRoomsForMove()
        }
    }
}
