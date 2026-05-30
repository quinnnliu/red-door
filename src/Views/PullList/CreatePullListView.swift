//
//  CreatePullListView.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/1/25.
//

import SwiftUI

struct CreatePullListView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: PullListViewModel = .init()

    @State private var showAddressSheet: Bool = false
    @State private var selectedAddressMode: String = "Search"
    let addressOptions = ["Search", "Entry"]
    @State private var address: String = ""
    @State private var installDate: Date = .init()
    @State private var uninstallDate: Date = .init()

    @State private var showCreateRoom: Bool = false
    private var rooms: [Room]?

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
                TextField("", text: $viewModel.selectedList.client)
                    .padding(6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }

            HStack(spacing: 0) {
                Text("Rooms:")
                    .font(.headline)
                    .foregroundColor(.red)

                Spacer()

                SmallCTA(type: .red, leadingIcon: "plus", text: "Add Room") {
                    showCreateRoom = true
                } 
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.rooms, id: \.self) { room in
                        EmptyRoomListItem(room.roomName)
                    }
                }
            }

            RDButton(variant: .red, size: .default, label: "Create Pull List", fullWidth: true) {
                viewModel.selectedList.installDate = installDate.formatted(.dateTime.year().month().day())
                viewModel.selectedList.uninstallDate = uninstallDate.formatted(.dateTime.year().month().day())
                viewModel.createPullList()
                dismiss()
            }
            .padding(.bottom, 16)
            
        }
        .toolbar(.hidden)
        .frameHorizontalPadding()
        .sheet(isPresented: $showCreateRoom) {
            CreateEmptyRoomSheet()
                .onAppear {
                    newRoomName = ""
                    keyboardFocused = true
                }
        }
        .sheet(isPresented: $showAddressSheet) {
            AddressSheet(selectedAddress: $viewModel.selectedList.address, addressId: $viewModel.selectedList.addressId)
        }
    }

    // MARK: TopBar

    @ViewBuilder 
    private func TopBar() -> some View {
        TopAppBar(leadingView: {
            BackButton()
        }, header: {
            RDButton(variant: .outline, size: .default, label: viewModel.selectedList.address.isInitialized() ? viewModel.selectedList.address.getStreetAddress() ?? "" : "Enter Address") {
                showAddressSheet = true
            }
        }, trailingView: {
            Spacer().frame(width: 32)
        })
    }

    // MARK: Create Empty Room Sheet

    @FocusState var keyboardFocused: Bool
    @State private var newRoomName: String = ""
    @State private var existingRoomAlert: Bool = false
    @ViewBuilder 
    private func CreateEmptyRoomSheet() -> some View {
        VStack(spacing: 16) {
            TextField("Room Name", text: $newRoomName)
                .focused($keyboardFocused)
                .submitLabel(.done)

            HStack(spacing: 0) {
                Button {
                    showCreateRoom = false
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }

                Spacer()

                Button {
                    existingRoomAlert = !viewModel.createEmptyRoom(newRoomName)
                    if !existingRoomAlert {
                        showCreateRoom = false
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

    // MARK: Empty Room List Item

    @ViewBuilder 
    private func EmptyRoomListItem(_ roomName: String) -> some View {
        HStack(spacing: 0) {
            Text(roomName)
                .foregroundStyle(Color(.label))
            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    CreatePullListView()
}
