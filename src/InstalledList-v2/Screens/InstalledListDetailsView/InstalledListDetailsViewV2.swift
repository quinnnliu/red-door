//
//  InstalledListDetailsViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/25/26.
//

import SwiftUI

struct InstalledListDetailsViewV2: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator.self) private var coordinator
    @State private var viewModel: InstalledListDetailsViewModelV2
    
    @State private var showDetails: Bool = false
    @State private var showUninstallListCover: Bool = false

    init(viewModel: InstalledListDetailsViewModelV2) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            TopBar

            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                    PrimaryImageView(image: viewModel.installedListState.primaryImage)

                    Section {
                        RoomsListContent
                    } header: {
                        RoomsListHeader
                    }
                }
            }

            Spacer(minLength: 0)

            if showDetails {
                ListDetails
            }

            FooterContent
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .toolbar(.hidden)
        .task {
            await viewModel.startListening()
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("Ok", role: .cancel) {}
        }
    }
}

private extension InstalledListDetailsViewV2 {

    // MARK: ShowDetailsButton
    var ShowDetailsButton: some View {
        RDButton(variant: showDetails ? .red : .secondary, leadingIcon: SFSymbols.infoCircleFill, label: "Details") {
            withAnimation(Constants.Animation.snappy) {
                showDetails.toggle()
            }
        }
    }

    var ListDetails: some View {
        Button {
            withAnimation(Constants.Animation.snappy) {
                showDetails = false
            }
        } label: {
            InstalledListDetailsSection(viewModel.installedListState)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top)),
                    removal:   .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                ))
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.red, lineWidth: 4)
                )
        }
    }

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
                    Text(viewModel.installedListState.address.getStreetAddress() ?? viewModel.installedListState.address.formattedAddress)
                }
            },
            trailingView: {
                TopBarMenu
            }
        )
    }

    // MARK: TopBar Menu
    var TopBarMenu: some View {
        Menu {
            Button("Refresh", systemImage: SFSymbols.arrowCounterclockwise) {
                viewModel.refreshInstalledListAndRooms()
            }
            .tint(.red)
        } label: {
            RDButton(
                variant: .red,
                size: .icon,
                leadingIcon: SFSymbols.ellipsis
            ) { }.clipShape(.circle)
        }
    }

    // MARK: InstalledListDetailsSection
    func InstalledListDetailsSection(_ list: InstalledListV2) -> some View {
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
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: RoomsListHeader
    var RoomsListHeader: some View {
        HStack {
            Spacer()
            Text("Rooms")
                .foregroundStyle(.red)
                .font(.headline)
            Spacer()
        }
        .background(Color(.systemBackground))
    }

    // MARK: RoomsListContent
    @ViewBuilder
    var RoomsListContent: some View {
        if viewModel.isLoading && viewModel.rooms.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            RoomList
        }
    }

    var RoomList: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.rooms, id: \.id) { room in
                let items = viewModel.itemsByRoom[room.id] ?? []
                RoomListItemView(room: room, itemCount: items.count, style: .pullListDetails, action: handleAction) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            RoomItemPreview(item, room: room)
                        }
                    }
                }
            }
        }
    }
}

private extension InstalledListDetailsViewV2 {
    func RoomItemPreview(_ item: ItemV2, room: RoomV2) -> some View {
        Button {
            coordinator.appendToSelectedPath(NavigationDestination.installedListItemDetailView(item: item, room: room))
        } label: {
            HStack(alignment: .center, spacing: 12) {
                PrimaryImageView(image: item.primaryImage, size: Constants.Image.listItemDefault, isExpandable: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: 4) {
                        Image(systemName: item.type.icon ?? SFSymbols.ellipsis)
                            .foregroundColor(.secondary)

                        if let color = item.color.color {
                            Image(systemName: SFSymbols.circleFill)
                                .foregroundColor(color)
                        }
                    }
                    .font(.caption)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(item.attention ? Color.yellow.opacity(0.75) : item.location.status == .inStorage ? Color(.systemGray3) : Color.red, lineWidth: 2)
            )
        }
    }
}

// MARK: - FooterContent

private extension InstalledListDetailsViewV2 {
    var FooterContent: some View {
        HStack {
            RDButton(variant: .red, leadingIcon: SFSymbols.shippingbox ,label: "Uninstall List") {
                showUninstallListCover = true
            }
            
            ShowDetailsButton
        }
    }
}

// MARK: Handle Action
private extension InstalledListDetailsViewV2 {
    func handleAction(_ actionArgument: Any?) {
        guard actionArgument != nil else { return }

        if let roomListItemAction = actionArgument as? RoomListItemViewAction {
            switch roomListItemAction {
            case .navigate(let room):
                coordinator.appendToSelectedPath(NavigationDestination.installedListRoomDetailView(
                    items: viewModel.itemsByRoom[room.id] ?? [],
                    room: room
                ))
            case .refreshRoom(let roomId):
                viewModel.refreshRoom(roomId)
            }
        }
    }
}
