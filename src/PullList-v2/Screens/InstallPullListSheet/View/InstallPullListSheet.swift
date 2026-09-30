//
//  InstallPullListSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/6/26.
//

import SwiftUI

struct InstallPullListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator.self) private var coordinator
    @State private var viewModel: InstallPullListSheetViewModel
    init(
        list: PullListV2,
        rooms: [RoomV2] = [],
        itemsByRoom: [String: [ItemV2]] = [:]
    ) {
        viewModel = InstallPullListSheetViewModel(from: list, rooms: rooms, itemsByRoom: itemsByRoom)
    }

    var body: some View {
        VStack(spacing: 16) {
            TopBar

            if viewModel.isReadOnly {
                ReadOnlyBanner
            }

            RoomList

            Spacer()

            if viewModel.isOwner {
                RDButton(
                    variant: .red,
                    size: .default,
                    leadingIcon: SFSymbols.plus,
                    label: "Create Installed List",
                    fullWidth: true
                ) {
                    viewModel.showConfirmSheet = true
                }
            }
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .task {
            await viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .alert(viewModel.alertText, isPresented: $viewModel.showAlert) {
            Button("Ok", role: .cancel) {
                // The alert is presented from this sheet, so dismissing has to
                // wait for acknowledgement or the message is never read.
                if viewModel.sessionEndedByOtherUser {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $viewModel.showConfirmSheet) {
            ConfirmInstallSheet(summary: viewModel.confirmInstallSummary, action: handleAction(_:))
        }
    }
}

extension InstallPullListSheet {
    // MARK: TopBar
    
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton()
            },
            header: {
                (
                    Text("Installing: ")
                        .foregroundStyle(.red)
                        .bold()
                    +
                    Text("\(viewModel.pullListState.address.getStreetAddress() ?? "loading")")
                )
                
            },
            trailingView: {
                EmptyTopBarIconButton()
            }
        )
    }
    
    // MARK: ReadOnlyBanner

    /// Also where a displaced user lands mid-session, so this doubles as the
    /// takeover affordance.
    var ReadOnlyBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: SFSymbols.infoCircleFill)
                .foregroundStyle(.secondary)

            Text("View only — someone is installing this list")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            RDButton(variant: .red, size: .sm, label: "Take Over") {
                Task { await viewModel.takeoverSession() }
            }
        }
    }

    // MARK: RoomItemList

    private var RoomList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.rooms) { room in
                    let items = viewModel.itemsByRoom[room.id] ?? []
                    ExpandableSectionView(
                        style: .installingRoom(room: room, itemCount: items.count),
                        isExpanded: false,
                        action: handleAction
                    ) {
                        LazyVStack(spacing: 8) {
                            ForEach(items) { item in
                                InstallItemListItemView(
                                    item: item,
                                    room: room,
                                    installStates: viewModel.resolvedItemDestinations,
                                    storageLocations: viewModel.storageLocations,
                                    action: handleAction
                                )
                                .allowsHitTesting(viewModel.isOwner)
                            }
                        }
                    }
                    .padding(4)
                }
            }
        }
    }
}

// MARK: InstallPullListRoomAction

enum InstallPullListRoomAction {
    case storeItem(itemId: String, storageLocationId: String)
    case installItem(itemId: String)
}

// MARK: handleAction

extension InstallPullListSheet {
    func handleAction(_ actionArgument: Any?) {
        guard let action = actionArgument else { return }
        
        switch action {
        case let sectionAction as ExpandableSectionAction:
            switch sectionAction {
            case .refreshRoom(let roomId):
                viewModel.refreshRoom(roomId)
            case .headerAction:
                return
            }
        case let roomAction as InstallPullListRoomAction:
            switch roomAction {
            case .installItem(let itemId):
                Task { await viewModel.installItem(itemId: itemId) }
            case .storeItem(let itemId, let storageLocationId):
                Task { await viewModel.storeItem(itemId: itemId, storageLocationId: storageLocationId) }
            }
        case let confirmAction as ConfirmInstallSheetAction:
            switch confirmAction {
            case .confirm:
                Task { @MainActor in
                    if let _ = await viewModel.createInstalledList(), !viewModel.showAlert {
                        try? await Task.sleep(for: .milliseconds(500))
                        coordinator.resetSelectedPath()
                        try? await Task.sleep(for: .milliseconds(500))
                        coordinator.setSelectedTab(to: .installedListV2)
                    }
                }
            }
        default:
            break
        }
    }
}
