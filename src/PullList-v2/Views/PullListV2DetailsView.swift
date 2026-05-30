//
//  PullListV2DetailsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/17/26.
//

import SwiftUI

struct PullListV2DetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PullListV2DetailsViewModel
    @State private var showAddRoomsSheet: Bool = false
    @State private var showEditListSheet: Bool = false // TODO: implement this

    init(list: PullListV2) {
        viewModel = PullListV2DetailsViewModel(from: list)
    }

    var body: some View {
        VStack(spacing: 16) {
            TopBar

            if viewModel.isLoading && viewModel.rooms.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(errorMessage)
            }
            
            PullListDetailsSection(viewModel.pullListState)

            RoomsListSection
        }
        .frameTop()
        .frameHorizontalPadding()
        .toolbar(.hidden)
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .alert(viewModel.alertText, isPresented: $viewModel.showAlert) {
            Button("Ok", role: .cancel) {}
        }
        .sheet(isPresented: $showAddRoomsSheet) {
            CreateEmptyRoomSheet(action: handleAction(_:))
        }
    }
}

extension PullListV2DetailsView {
    
    // MARK: TopBar
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton()
            },
            header: {
                HStack {
                    Text("Address:")
                        .bold()
                        .foregroundStyle(.red)
                    Text(viewModel.pullListState.address.getStreetAddress() ?? viewModel.pullListState.address.formattedAddress)
                }
            },
            trailingView: {
                HStack(spacing: 8) {
                    RDButton(
                        variant: .outline,
                        size: .icon,
                        leadingIcon: SFSymbols.arrowCounterclockwise
                    ) {
                        viewModel.refreshPullList()
                    }

                    TopBarMenu
                }
            }
        )
    }
    
    // MARK: TopBar Right Icon Menu
    @ViewBuilder
    var TopBarMenu: some View {
        Menu {
            Group {
                Button("Add Room", systemImage: SFSymbols.plus) {
                    showAddRoomsSheet = true
                }
                
                Button("Edit List Details", systemImage: SFSymbols.pencil) {
                    showEditListSheet = true
                }
                
                Button("Delete Pull List", systemImage: SFSymbols.trash) {
                    Task {
                        viewModel.deletePullList()
                        dismiss()
                    }
                }
            }
            .tint(.red)
        } label: {
            RDButton(
                variant: .red,
                size: .icon,
                leadingIcon: SFSymbols.ellipsis,
                iconBold: true
            ) { }
        }
    }
    
    // MARK: Error View
    func ErrorView(_ errorMessage: String) -> some View {
        VStack(spacing: 8) {
            Text("Error")
                .font(.headline)
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
    
    // MARK: PullListDetailsSection
    func PullListDetailsSection(_ list: PullListV2) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            (
                Text("Address: ")
                    .foregroundColor(.red)
                    .bold()
                +
                Text(list.address.formattedAddress)
                    .foregroundColor(.primary)
            )
            
            (
                Text("Install Date: ")
                    .foregroundColor(.red)
                    .bold()
                +
                Text(list.installDate)
                    .foregroundColor(.primary)
            )
            
            (
                Text("Uninstall Date: ")
                    .foregroundColor(.red)
                    .bold()
                +
                Text(list.uninstallDate)
                    .foregroundColor(.primary)
            )
            
            (
                Text("Client: ")
                    .foregroundColor(.red)
                    .bold()
                +
                Text(list.clientId)
                    .foregroundColor(.primary)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(.systemGray3), lineWidth: 4)
        )
    }
    
    // MARK: RoomsListView
    @ViewBuilder
    var RoomsListSection: some View {
        if !viewModel.rooms.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Rooms")
                    .font(.headline)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.rooms, id: \.id) { room in
                            NavigationLink(value: NavigationDestination.roomDetailView(
                                room: room,
                                list: viewModel.pullListState
                            )) {
                                RoomListItemView(
                                    room: room,
                                    list: viewModel.pullListState,
                                    items: viewModel.itemsByRoom[room.id] ?? [],
                                    action: handleAction(_:)
                                )
                            }
                        }
                    }
                }
            }
        } else {
            Text("No rooms")
        }
    }
}

// MARK: Handle Action
extension PullListV2DetailsView {
    func handleAction(_ actionArgument: Any?) {
        guard actionArgument != nil else { return }
        
        if let roomListItemAction = actionArgument as? RoomListItemViewAction {
            switch roomListItemAction {
            case .refreshRoom(let roomId):
                viewModel.refreshRoom(roomId)
            }
        } else if let createRoomAction = actionArgument as? CreateEmptyRoomAction {
            switch createRoomAction {
            case .createEmptyRoom(let newRoomName):
                viewModel.createEmptyRoom(newRoomName)
            }
        }
    }
}
