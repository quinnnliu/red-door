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
    @State private var showEditListSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showPDFSheet: Bool = false
    @State private var showInstallListSheet: Bool = false
    @State private var footerContentState: FooterContentState? = nil
    @State private var showUnassignedItems: Bool = false
    @State private var showSelectStorageSheet: Bool = false
    @State private var showSelectRoomForUnassignedSheet: Bool = false
    @State private var showStoreUnassignedItemSheet: Bool = false
    @State private var itemToStore: ItemV2? = nil

    init(viewModel: PullListDetailsViewModelV2) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: Constants.Padding(2)) {
            VStack(spacing: Constants.Padding(0.25)) {
                TopBar
                
                if let copiedFrom = viewModel.pullListState.copiedFromDisplayName {
                    Text("Copy of \(copiedFrom)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            ScrollView {
                LazyVStack(spacing: Constants.Padding(2), pinnedViews: .sectionHeaders) {
                    PrimaryImageView(image: viewModel.pullListState.image)
                    Section {
                        RoomsListContent
                    } header: {
                        RoomsListHeader
                    }
                }
            }

            Spacer(minLength: 0)

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
        .sheet(isPresented: $showSelectStorageSheet) {
            SelectDocumentSheet(
                title: "Select Essentials Storage Location",
                documents: viewModel.availableStorageLocations,
                refreshAction: { Task { await viewModel.fetchAvailableStorageLocations() } },
                action: handleAction(_:)
            )
            .task { await viewModel.fetchAvailableStorageLocations() }
        }
        .sheet(isPresented: $showEditListSheet) {
            PullListViewFactory().makeEditView(list: viewModel.pullListState)
        }
        .confirmationDialog(
            "Delete this pull list?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Pull List", role: .destructive) {
                Task {
                    if await viewModel.deletePullList() { dismiss() }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes the list and its image.")
        }
        .sheet(isPresented: $showAddRoomsSheet) {
            EditRoomV2Sheet { newRoomName, squareFootage in
                Task {
                    await viewModel.createEmptyRoom(newRoomName, squareFootage: squareFootage)
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
        RDButton(variant: .secondary, size: .icon, leadingIcon: SFSymbols.infoCircleFill) {
            withAnimation(Constants.Animation.snappy) {
                footerContentState = .details
            }
        }
    }

    var ListDetails: some View {
        Button {
            withAnimation(Constants.Animation.snappy) {
                footerContentState = nil
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
                    Image(systemName: SFSymbols.mapPinAndEllipse)
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

                Button("Delete", systemImage: SFSymbols.trash, role: .destructive) {
                    showDeleteConfirmation = true
                }
                .disabled(!viewModel.canDelete)

                if !viewModel.canDelete {
                    Text("Remove all rooms and items first")
                }
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

    // MARK: PullListDetailsSection
    func PullListDetailsSection(_ list: PullListV2) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 4) {
                (
                    Text("Address: ")
                        .foregroundColor(.red)
                        .bold()
                    +
                    Text(list.address.formattedAddress)
                        .foregroundColor(.primary)
                )
                
                if let copiedFrom = list.copiedFromDisplayName {
                    Text("Copy of \(copiedFrom)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            
            (
                Text("Install Date: ")
                    .foregroundColor(.red)
                    .bold()
                +
                Text(list.installDate.displayDate)
                    .foregroundColor(.primary)
            )

            (
                Text("Uninstall Date: ")
                    .foregroundColor(.red)
                    .bold()
                +
                Text(list.uninstallDate.displayDate)
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

            if let squareFootage = list.squareFootage {
                (
                    Text("Square Footage: ")
                        .foregroundColor(.red)
                        .bold()
                    +
                    Text(squareFootage)
                        .foregroundColor(.primary)
                )
            }
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var EssentialsGroupSectionHeader: some View {
        Text("Essentials")
            .foregroundStyle(.red)
            .font(.headline)
    }

    // MARK: EssentialsGroupSectionContent
    @ViewBuilder
    var EssentialsGroupSectionContent: some View {
        if let group = viewModel.essentialsGroupState {
            LazyVStack(spacing: 8) {
                HStack(spacing: 2) {
                    EssentialsGroupListItemView(group: group, emoji: group.emoji, action: handleAction(_:))

                    Button {
                        showSelectStorageSheet = true
                    } label: {
                        Image(systemName: SFSymbols.xmarkCircleFill)
                            .foregroundStyle(.gray)
                            .font(.title3)
                    }
                }
                
                if let accessories = viewModel.essentialsAccessories {
                    Text("Accessories")
                        .font(.callout)
                    AccessoriesListItemView(accessories)
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
                            .foregroundStyle(.red)
                    }
                }
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.unassignedItems), id: \.id) { item in
                        HStack(spacing: 8) {
                            ItemListItemView(
                                item: item,
                                style: .addToDocument,
                                isSelected: viewModel.isUnassignedSelected(item),
                                action: handleAction(_:)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                handleAction(
                                    viewModel.isUnassignedSelected(item) ?
                                    ItemListItemAction.multiSelectDeselection(item)
                                    : ItemListItemAction.multiSelectSelection(item)
                                )
                            }

                            if item.essentialGroupId == nil {
                                RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.shippingbox) {
                                    itemToStore = item
                                    showStoreUnassignedItemSheet = true
                                }
                            }
                        }
                    }
                }
            }

            RDButton(
                variant: viewModel.selectedUnassignedItems.isEmpty ? .secondary : .red,
                leadingIcon: SFSymbols.plus,
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
        .sheet(isPresented: $showStoreUnassignedItemSheet, onDismiss: { itemToStore = nil }) {
            SelectDocumentSheet(
                title: "Select Storage Location",
                documents: viewModel.availableStorageLocations,
                refreshAction: { Task { await viewModel.fetchAvailableStorageLocations() } },
                action: handleAction(_:)
            )
            .task { await viewModel.fetchAvailableStorageLocations() }
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
        .padding(.bottom, 8)
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
                ExpandableSectionView(
                    style: .pullListRoom(room: room, itemCount: items.count),
                    isExpanded: false,
                    action: handleAction
                ) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            RoomItemPreview(item, action: handleAction)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - FooterContent

private extension PullListDetailsViewV2 {
    enum FooterContentState {
        case details, essentials
    }
    
    @ViewBuilder
    var FooterContent: some View {
        switch footerContentState {
        case .details:
            ListDetails
        case .essentials:
            EssentialsGroupContent
        default:
            HStack {
                ShowDetailsButton
                
                RDButton(
                    variant: .red,
                    leadingIcon: SFSymbols.truckBoxBadgeClockFill,
                    label: "Begin Install",
                    fullWidth: true
                ) {
                    showInstallListSheet = true
                }
                .disabled(viewModel.pullListState.unassignedItemIds.count > 0)
                
                ShowEssentialsButton
            }
        }
    }
    
    var EssentialsGroupContent: some View {
        Button {
            withAnimation(Constants.Animation.snappy) {
                footerContentState = nil
            }
        } label: {
            VStack(spacing: 4) {
                EssentialsGroupSectionHeader
                EssentialsGroupSectionContent
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top)),
                removal:   .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
            ))
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.red, lineWidth: 4)
            )
        }
        
    }
    
    @ViewBuilder
    var ShowEssentialsButton: some View {
        if let essentialsGroup = viewModel.essentialsGroupState {
            RDButton(variant: .secondary, size: .icon, label: essentialsGroup.emoji) {
                withAnimation(Constants.Animation.snappy) {
                    footerContentState = .essentials
                }
            }
        }
    }
}

// MARK: Handle Action
private extension PullListDetailsViewV2 {
    func handleAction(_ actionArgument: Any?) {
        guard actionArgument != nil else { return }

        if let sectionAction = actionArgument as? ExpandableSectionAction {
            switch sectionAction {
            case .headerAction(.pullListRoom(let room, _)):
                coordinator.appendToSelectedPath(NavigationDestination.pulllistRoomDetailView(
                    items: viewModel.itemsByRoom[room.id] ?? [],
                    room: room
                ))
            case .refreshRoom(let roomId):
                viewModel.refreshRoom(roomId)
            default:
                break
            }
        }

        if let previewAction = actionArgument as? RoomItemPreviewAction {
            switch previewAction {
            case .navigate(let item):
                if let room = viewModel.rooms.first(where: { viewModel.itemsByRoom[$0.id]?.contains(item) == true }) {
                    coordinator.appendToSelectedPath(NavigationDestination.pullListItemDetailView(item: item, room: room))
                }
            }
        }

        if let storageAction = actionArgument as? SelectDocumentSheetAction<StorageLocation> {
            switch storageAction {
            case .selected(let storageLocation):
                if let item = itemToStore {
                    Task {
                        await viewModel.storeUnassignedItem(item, in: storageLocation)
                        itemToStore = nil
                    }
                } else {
                    Task { await viewModel.removeEssentialsGroup(to: storageLocation) }
                    footerContentState = nil
                }
            default:
                break
            }
        }

        if let itemAction = actionArgument as? ItemListItemAction {
            switch itemAction {
            case .multiSelectSelection(let item):
                withAnimation(Constants.Animation.snappy) {
                    viewModel.selectUnassigned(item)
                }
            case .multiSelectDeselection(let item):
                withAnimation(Constants.Animation.snappy) {
                    viewModel.deselectUnassigned(item)
                }
            default:
                break
            }
        }

        if let roomAction = actionArgument as? SelectDocumentSheetAction<RoomV2> {
            switch roomAction {
            case .selected(let room):
                Task { await viewModel.assignSelectedItemsToRoom(room) }
            default:
                break
            }
        }
        
        if let essentialsAction = actionArgument as? EssentialsGroupListItemAction {
            switch essentialsAction {
            case .navigate(let group):
                coordinator.appendToSelectedPath(NavigationDestination.essentialsGroupDetailView(group))
            }
        }
    }

}
