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
    
    @State private var footerContentState: FooterContentState? = nil
    @State private var showPDFSheet: Bool = false
    @State private var showUninstallListCover: Bool = false
    @State private var showUninstallRecordSheet: Bool = false

    init(viewModel: InstalledListDetailsViewModelV2) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            TopBar

            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                    PrimaryImageView(image: viewModel.installedListState.image)

                    Section {
                        RoomsListContent
                    } header: {
                        RoomsListHeader
                    }
                }
            }

            Spacer(minLength: 0)

            FooterContent
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .toolbar(.hidden)
        .fullScreenCover(isPresented: $showUninstallListCover) {
            InstalledListViewFactory().makeUninstallSheet(list: viewModel.installedListState)
        }
        .fullScreenCover(isPresented: $showPDFSheet) {
            InstalledListViewFactory().makePDFView(list: viewModel.installedListState)
        }
        .sheet(isPresented: $showUninstallRecordSheet) {
            InstalledListViewFactory().makeUninstallRecordSheet(list: viewModel.installedListState)
        }
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
        RDButton(style: .secondary, size: .icon, leadingIcon: SFSymbols.infoCircleFill) {
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
                    Image(systemName: SFSymbols.mapPinAndEllipse)
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
                style: .red,
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

    // MARK: EssentialsGroupSectionHeader
    var EssentialsGroupSectionHeader: some View {
        Text("Essentials")
            .foregroundStyle(.red)
            .font(.headline)
            .padding(12)
            .background(.gray.opacity(0.5))
            .cornerRadius(12)
    }

    // MARK: EssentialsGroupSectionContent
    @ViewBuilder
    var EssentialsGroupSectionContent: some View {
        if let group = viewModel.essentialsGroupState {
            LazyVStack(spacing: 8) {
                EssentialsGroupListItemView(group: group, emoji: group.emoji, action: handleAction(_:))

                if let accessories = viewModel.essentialsAccessories {
                    Text("Accessories")
                        .font(.caption)
                        .foregroundStyle(.primary)
                    AccessoriesListItemView(accessories)
                }
            }
        }
    }

    // MARK: RoomsListHeader
    var RoomsListHeader: some View {
        ZStack {
            Text("Rooms")
                .foregroundStyle(.red)
                .font(.headline)

            HStack(spacing: .zero) {
                SmallCTA(type: .secondary, leadingIcon: SFSymbols.richtextPageFill, text: "Show PDF") {
                    showPDFSheet = true
                }

                Spacer()
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
                            RoomItemPreview(item, action: handleAction(_:))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - FooterContent

private extension InstalledListDetailsViewV2 {
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

                if !viewModel.installedListState.uninstalled {
                    RDButton(style: .red, leadingIcon: SFSymbols.shippingbox, label: "Uninstall List", fullWidth: true) {
                        showUninstallListCover = true
                    }
                } else {
                    RDButton(style: .outline, leadingIcon: SFSymbols.shippingbox, label: "Uninstall Summary", fullWidth: true) {
                        showUninstallRecordSheet = true
                    }
                }

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
            VStack(spacing: 12) {
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
            RDButton(style: .secondary, size: .icon, label: essentialsGroup.emoji) {
                withAnimation(Constants.Animation.snappy) {
                    footerContentState = .essentials
                }
            }
        }
    }
}

// MARK: Handle Action
private extension InstalledListDetailsViewV2 {
    func handleAction(_ actionArgument: Any?) {
        guard actionArgument != nil else { return }

        if let previewAction = actionArgument as? RoomItemPreviewAction {
            switch previewAction {
            case .navigate(let item):
                if let room = viewModel.rooms.first(where: { viewModel.itemsByRoom[$0.id]?.contains(item) == true }) {
                    coordinator.appendToSelectedPath(
                        NavigationDestination.installedListItemDetailView(
                            item: item,
                            room: room,
                            uninstalled: viewModel.installedListState.uninstalled
                        )
                    )
                }
            }
        }

        if let sectionAction = actionArgument as? ExpandableSectionAction {
            switch sectionAction {
            case .headerAction(.pullListRoom(let room, _)):
                coordinator.appendToSelectedPath(NavigationDestination.installedListRoomDetailView(
                    items: viewModel.itemsByRoom[room.id] ?? [],
                    room: room,
                    uninstalled: viewModel.installedListState.uninstalled
                ))
            case .refreshRoom(let roomId):
                viewModel.refreshRoom(roomId)
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
