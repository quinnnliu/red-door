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
    @State private var showPDFSheet: Bool = false
    @State private var showInstallListSheet: Bool = false

    init(list: PullListV2) {
        viewModel = PullListV2DetailsViewModel(from: list)
    }

    var body: some View {
        VStack(spacing: 16) {
            TopBar

            if viewModel.isLoading && viewModel.rooms.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            
            PullListDetailsSection(viewModel.pullListState)

            RoomsListSection
            
            Spacer()
            
            RDButton(
                variant: viewModel.canOpenInstallSheet ? .red : .secondary,
                leadingIcon: SFSymbols.truckBoxBadgeClockFill,
                label: viewModel.canOpenInstallSheet ? "Begin Install" : "Being Installed...",
                fullWidth: true
            ) {
                handleInstallListAction()
            }
        }
        .frameTop()
        .frameHorizontalPadding()
        .toolbar(.hidden)
        .onAppear {
            viewModel.startListening()
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("Ok", role: .cancel) {}
        }
        .alert("Install in Progress", isPresented: $viewModel.showInstallBlockedAlert) {
            Button("Clear Lock", role: .destructive) {
                viewModel.clearInstallingSession()
            }
            Button("Cancel", role: .cancel) {
                Task { await viewModel.refreshPullListDetails() }
            }
        } message: {
            Text(viewModel.getInstallBlockedMessage())
        }
        .sheet(isPresented: $showAddRoomsSheet) {
            EditRoomV2Sheet { newRoomName in
                Task {
                    await viewModel.createEmptyRoom(newRoomName)
                }
            }
        }
        .fullScreenCover(isPresented: $showInstallListSheet) {
            InstallPullListSheet(list: viewModel.pullListState, rooms: viewModel.rooms, itemsByRoom: viewModel.itemsByRoom)
        }
        .fullScreenCover(isPresented: $showPDFSheet) {
            PullListPDFViewV2(list: viewModel.pullListState)
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.separator), lineWidth: 3)
                )
            },
            trailingView: {
                HStack(spacing: 8) {
                    TopBarMenu
                }
            }
        )
    }
    
    // MARK: TopBar Right Icon Menu
    var TopBarMenu: some View {
        Menu {
            Group {
                Button("Edit List Details", systemImage: SFSymbols.pencil) {
                    showEditListSheet = true
                }
                
                Button("Refresh List", systemImage: SFSymbols.arrowCounterclockwise) {
                    viewModel.refreshPullListAndRooms()
                }

                if viewModel.pullListState.installingSession != nil {
                    Button("Clear Install Lock", systemImage: SFSymbols.xmark, role: .destructive) {
                        viewModel.clearInstallingSession()
                    }
                }

                Button("Delete Pull List", systemImage: SFSymbols.trash, role: .destructive) {
                    Task {
                        await viewModel.deletePullList()
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
            ) { }.clipShape(.circle)
        }
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
                .stroke(Color(.systemGray3), lineWidth: 3)
        )
    }
    
    // MARK: RoomsListView
    @ViewBuilder
    var RoomsListSection: some View {
        if !viewModel.rooms.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: .zero) {
                    SmallCTA(type: .secondary, leadingIcon: SFSymbols.richtextPageFill, text: "Show PDF") {
                        showPDFSheet = true
                    }
                    
                    Spacer()

                    Text("Rooms")
                        .foregroundStyle(.red)
                        .font(.headline)
                    
                    Spacer()
                    
                    SmallCTA(type: .red, leadingIcon: SFSymbols.plus, text: "Add Room") {
                        showAddRoomsSheet = true
                    }
                }
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.rooms, id: \.id) { room in
                            NavigationLink(value: NavigationDestination.pulllistRoomDetailView(
                                items: viewModel.itemsByRoom[room.id] ?? [],
                                room: room
                            )) {
                                PullListRoomListItem(
                                    room: room,
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
        }
    }
    
    func handleInstallListAction() {
        if viewModel.canOpenInstallSheet {
            Task {
                let didCreate = await viewModel.createInstallingSession()
                if didCreate {
                    showInstallListSheet = true
                }
            }
        } else {
            viewModel.showInstallBlockedAlert = true
        }
    }
}
