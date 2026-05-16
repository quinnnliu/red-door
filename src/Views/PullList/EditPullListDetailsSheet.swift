//
//  EditPullListDetailsSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/9/25.
//

import SwiftUI

struct EditPullListDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var viewModel: PullListViewModel
    @State private var editingList: RDList
    @State private var newRoomNames: [String] = []
    @State private var installDate: Date
    @State private var uninstallDate: Date

    @State private var showAddressSheet: Bool = false
    @State private var showAddRoom: Bool = false

    @FocusState var keyboardFocused: Bool
    @State private var newRoomName: String = ""
    @State private var existingRoomAlert: Bool = false

    init(viewModel: Binding<PullListViewModel>) {
        _viewModel = viewModel
        self.editingList = viewModel.wrappedValue.selectedList
        self.installDate = (try? Date(viewModel.wrappedValue.selectedList.installDate, strategy: .dateTime.year().month().day())) ?? Date()
        self.uninstallDate = (try? Date(viewModel.wrappedValue.selectedList.uninstallDate, strategy: .dateTime.year().month().day())) ?? Date()
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 12) {
            TopBar()

            DatePicker(
                selection: $installDate,
                displayedComponents: [.date]
            ) {
                Text("Install Date:")
                    .foregroundColor(.secondary)
                    .bold()
            }

            DatePicker(
                selection: $uninstallDate,
                displayedComponents: [.date]
            ) {
                Text("Uninstall Date:")
                    .foregroundColor(.red)
                    .bold()
            }

            HStack {
                Text("Client:")
                TextField("", text: $editingList.client)
                    .padding(6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }

            RoomsList()
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameVerticalPadding()
        .presentationDetents([.medium])
        .sheet(isPresented: $showAddressSheet) {
            AddressSheet(selectedAddress: $editingList.address, addressId: $editingList.addressId)
        }
        .sheet(isPresented: $showAddRoom) {
            AddRoomSheet()
                .onAppear {
                    newRoomName = ""
                    keyboardFocused = true
                }
        }
    }

    // MARK: Top Bar
    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(leadingIcon: {
            RDButton(variant: .red, size: .icon, leadingIcon: "xmark", iconBold: true, fullWidth: false) {
                dismiss()
            }
            .clipShape(Circle())
        }, header: {
            RDButton(variant: .outline, size: .default, label: editingList.address.isInitialized() ? editingList.address.getStreetAddress() ?? "" : "Enter Address") {
                showAddressSheet = true
            }
        }, trailingIcon: {
            RDButton(variant: .red, size: .icon, leadingIcon: "checkmark", iconBold: true, fullWidth: false) {
                let installDateString = installDate.formatted(.dateTime.year().month().day())
                if installDateString != viewModel.selectedList.installDate {
                    viewModel.selectedList.installDate = installDateString
                }
                let uninstallDateString = uninstallDate.formatted(.dateTime.year().month().day())
                if uninstallDateString != viewModel.selectedList.uninstallDate {
                    viewModel.selectedList.uninstallDate = uninstallDateString
                }
                if editingList != viewModel.selectedList {
                    viewModel.selectedList = editingList
                    Task {
                        await viewModel.updateSelectedList(newRoomNames: newRoomNames)
                        await viewModel.loadRooms()
                    }
                }
                dismiss()
            }
            .clipShape(Circle())
        })
    }

    // MARK: Rooms List
    @ViewBuilder
    private func RoomsList() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Text("Rooms:")
                    .font(.headline)
                    .foregroundColor(.red)

                Spacer()

                SmallCTA(type: .red, leadingIcon: "plus", text: "Add Room") {
                    showAddRoom = true
                    newRoomName = ""
                }
            }

            ScrollView {
                LazyVStack {
                    ForEach(editingList.roomIds, id: \.self) { roomId in
                        let roomName = roomId.replacingOccurrences(of: "-", with: " ").capitalized
                        RoomListItem(roomName: roomName)
                    }
                }
            }
        }
    }


    // MARK: Create Empty Room Sheet
    @ViewBuilder
    private func AddRoomSheet() -> some View {
        VStack(spacing: 16) {
            TextField("Room Name", text: $newRoomName)
                .focused($keyboardFocused)
                .submitLabel(.done)

            HStack(spacing: 0) {
                Button {
                    showAddRoom = false
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }

                Spacer()

                Button {
                    // Creating a new room
                    existingRoomAlert = viewModel.roomExists(newRoomName: newRoomName, roomIds: editingList.roomIds)
                    if !existingRoomAlert {
                        editingList.roomIds.append(Room.nameToId(roomName: newRoomName))
                        newRoomNames.append(newRoomName)
                        showAddRoom = false
                    }
                } label: {
                    Text("Add Room")
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }
        }
        .alert("Room with that name already exists.", isPresented: $existingRoomAlert) {
            Button("Ok", role: .cancel) {}
        }
        .frameTop()
        .padding(24)
        .presentationDetents([.fraction(0.125)])
    }

    // MARK: Room List Item

    @ViewBuilder
    private func RoomListItem(roomName: String) -> some View {
        HStack(spacing: 0) {
            Text(roomName)
                .foregroundStyle(Color(.label))

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
