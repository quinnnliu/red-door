//
//  PullListDetailsViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/17/26.
//

import SwiftUI

struct PullListDetailsViewV2: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator.self) private var coordinator
    @State private var viewModel: PullListDetailsViewModelV2
    @State private var showAddRoomsSheet: Bool = false
    @State private var showEditListSheet: Bool = false // TODO: implement this
    @State private var showPDFSheet: Bool = false
    @State private var showInstallListSheet: Bool = false
    @State private var showDetails: Bool = false
    @State private var showUnassignedItems: Bool = false
    @State private var showSelectWarehouseSheet: Bool = false
    @State private var showSelectRoomForUnassignedSheet: Bool = false

    init(viewModel: PullListDetailsViewModelV2) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            TopBar

            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                    HStack {
                        PrimaryImageView(image: viewModel.pullListState.image)
                        VStack {
                            EssentialsGroupSectionHeader
                            EssentialsGroupSectionContent
                        }

                    }

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

            UnassignedItemsButton

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
        .sheet(isPresented: $showSelectWarehouseSheet) {
            SelectDocumentSheet(
                title: "Select Storage Location",
                documents: viewModel.availableWarehouses,
                action: handleAction(_:),
                refreshAction: { Task { await viewModel.fetchAvailableWarehouses() } }
            )
            .task { await viewModel.fetchAvailableWarehouses() }
        }
        .sheet(isPresented: $showAddRoomsSheet) {
            EditRoomV2Sheet { newRoomName in
                Task {
                    await viewModel.createEmptyRoom(newRoomName)
                }
            }
        }
        .sheet(isPresented: $showUnassignedItems) {
            UnassignedItemsContent
        }
        .fullScreenCover(isPresented: $showInstallListSheet) {
            InstallPullListSheet(list: viewModel.pullListState, rooms: viewModel.rooms, itemsByRoom: viewModel.itemsByRoom)
        }
        .fullScreenCover(isPresented: $showPDFSheet) {
            PullListPDFViewV2(list: viewModel.pullListState)
        }
    }
}

private extension PullListDetailsViewV2 {

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
            PullListDetailsSection(viewModel.pullListState)
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
                    Text(viewModel.pullListState.address.getStreetAddress() ?? viewModel.pullListState.address.formattedAddress)
                }
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
                Button("Edit Details", systemImage: SFSymbols.pencil) {
                    showEditListSheet = true
                }

                Button("Refresh", systemImage: SFSymbols.arrowCounterclockwise) {
                    viewModel.refreshPullListAndRooms()
                }

                if viewModel.pullListState.installingSession != nil {
                    Button("Clear Install Lock", systemImage: SFSymbols.xmark, role: .destructive) {
                        viewModel.clearInstallingSession()
                    }
                }

                Button("Delete", systemImage: SFSymbols.trash, role: .destructive) {
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
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: EssentialsGroupSectionHeader
    var EssentialsGroupSectionHeader: some View {
        HStack(spacing: 16) {
            Text("Essentials:")
                .foregroundStyle(.red)
                .font(.headline)

            Spacer()

            Button {
                showSelectWarehouseSheet = true
            } label: {
                Image(systemName: SFSymbols.xmarkCircleFill)
                    .foregroundStyle(.gray)
                    .font(.title3)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: EssentialsGroupSectionContent
    @ViewBuilder
    var EssentialsGroupSectionContent: some View {
        if let group = viewModel.essentialsGroupState {
            LazyVStack(spacing: 8) {
                HStack {
                    Text(group.emoji)
                    Text(group.displayName)
                        .font(.subheadline)
                    Spacer()
                }
                .font(.subheadline)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                if let accessories = viewModel.essentialsAccessories {
                    HStack {
                        Image(systemName: SFSymbols.wrenchFill)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text(accessories.displayName)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: UnassignedItemsButton
    var UnassignedItemsButton: some View {
        RDButton(
            variant: viewModel.unassignedItems.isEmpty ? .secondary : .red,
            size: .sm,
            label: "Unassigned Items: \(viewModel.unassignedItems.count)"
        ) {
            showUnassignedItems = true
        }
        .disabled(viewModel.unassignedItems.isEmpty)
    }

    // MARK: UnassignedItemsContent

    var UnassignedItemsContent: some View {
        VStack(spacing: 12) {
            DragIndicator()

            HStack {
                Text("Unassigned Items")
                    .font(.headline)
                    .foregroundStyle(.red)

                Spacer()

                if !viewModel.selectedUnassignedItems.isEmpty {
                    Button {
                        viewModel.deselectAllUnassigned()
                    } label: {
                        Text("Deselect All")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.unassignedItems), id: \.id) { item in
                        ItemListItemView(
                            item: item,
                            style: .addToDocument,
                            isSelected: viewModel.isUnassignedSelected(item),
                            action: handleAction(_:)
                        )
                    }
                }
            }

            RDButton(
                variant: viewModel.selectedUnassignedItems.isEmpty ? .secondary : .red,
                leadingIcon: SFSymbols.plus,
                iconBold: true,
                label: "Assign to Room (\(viewModel.selectedUnassignedItems.count))",
                fullWidth: true
            ) {
                showSelectRoomForUnassignedSheet = true
            }
            .disabled(viewModel.selectedUnassignedItems.isEmpty)
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .sheet(isPresented: $showSelectRoomForUnassignedSheet) {
            SelectDocumentSheet(
                title: "Select Room",
                documents: viewModel.rooms,
                action: handleAction(_:)
            )
        }
    }

    // MARK: RoomsListHeader
    var RoomsListHeader: some View {
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

private extension PullListDetailsViewV2 {
    func RoomItemPreview(_ item: ItemV2, room: RoomV2) -> some View {
        Button {
            coordinator.appendToSelectedPath(NavigationDestination.pullListItemDetailView(item: item, room: room))
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

private extension PullListDetailsViewV2 {
    var FooterContent: some View {
        HStack {
            RDButton(
                variant: viewModel.canOpenInstallSheet ? .red : .secondary,
                leadingIcon: viewModel.canOpenInstallSheet ?  SFSymbols.truckBoxBadgeClockFill : SFSymbols.lockFill,
                label: viewModel.canOpenInstallSheet ? "Begin Install" : "Being Installed...",
                fullWidth: true
            ) {
                handleInstallListAction()
            }

            ShowDetailsButton
        }
        .cornerRadius(12)
    }
}

// MARK: Handle Action
private extension PullListDetailsViewV2 {
    func handleAction(_ actionArgument: Any?) {
        guard actionArgument != nil else { return }

        if let roomListItemAction = actionArgument as? RoomListItemViewAction {
            switch roomListItemAction {
            case .navigate(let room):
                coordinator.appendToSelectedPath(NavigationDestination.pulllistRoomDetailView(
                    items: viewModel.itemsByRoom[room.id] ?? [],
                    room: room
                ))
            case .refreshRoom(let roomId):
                viewModel.refreshRoom(roomId)
            }
        }

        if let warehouseAction = actionArgument as? SelectDocumentSheetAction<WarehouseV2> {
            switch warehouseAction {
            case .selected(let warehouse):
                Task { await viewModel.removeEssentialsGroup(to: warehouse) }
            }
        }

        if let itemAction = actionArgument as? ItemListItemAction {
            switch itemAction {
            case .multiSelectSelection(let item):
                viewModel.selectUnassigned(item)
            case .multiSelectDeselection(let item):
                viewModel.deselectUnassigned(item)
            default:
                break
            }
        }

        if let roomAction = actionArgument as? SelectDocumentSheetAction<RoomV2> {
            switch roomAction {
            case .selected(let room):
                Task { await viewModel.assignSelectedItemsToRoom(room) }
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
