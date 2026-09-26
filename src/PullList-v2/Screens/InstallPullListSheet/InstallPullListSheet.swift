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
            
            RoomList
            
            Spacer()
            
            RDButton(variant: .red, size: .default, leadingIcon: SFSymbols.plus, label: "Create Installed List", fullWidth: true) {
                viewModel.showConfirmSheet = true
            }
            .disabled(viewModel.itemsByRoom.values.allSatisfy { $0.isEmpty })
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .task {
            viewModel.startListening()
            await viewModel.getWarehouses()
        }
        .alert(viewModel.alertText, isPresented: $viewModel.showAlert) {
            Button("Ok", role: .cancel) {}
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
                BackButton(action: {
                    Task {
                        await viewModel.clearInstallingSession()
                    }
                })
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
    
    // MARK: RoomItemList

    private var RoomList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.rooms) { room in
                    let items = viewModel.itemsByRoom[room.id] ?? []
                    RoomListItemView(room: room, itemCount: items.count, style: .installingPullList, action: handleAction) {
                        LazyVStack(spacing: 8) {
                            ForEach(items) { item in
                                InstallItemListItemView(
                                    item: item,
                                    installStates: viewModel.itemLocationState,
                                    warehouses: viewModel.warehouses,
                                    action: handleAction
                                )
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
    case storeItem(itemId: String, warehouseId: String)
    case installItem(itemId: String)
}

// MARK: handleAction

extension InstallPullListSheet {
    func handleAction(_ actionArgument: Any?) {
        guard let action = actionArgument else { return }
        
        switch action {
        case let roomViewAction as RoomListItemViewAction:
            switch roomViewAction {
            case .refreshRoom(let roomId):
                viewModel.refreshRoom(roomId)
            case .navigate:
                return
            }
        case let roomAction as InstallPullListRoomAction:
            switch roomAction {
            case .installItem(let itemId):
                viewModel.itemLocationState.updateValue(DocumentLocation(status: .inInstalledList, locationId: viewModel.pullListState.id), forKey: itemId)
            case .storeItem(let itemId, let warehouseId):
                viewModel.itemLocationState.updateValue(DocumentLocation(status: .inStorage, locationId: warehouseId), forKey: itemId)
            }
        case let confirmAction as ConfirmInstallSheetAction:
            switch confirmAction {
            case .confirm:
                Task { @MainActor in
                    if let installedList = await viewModel.createInstalledList(), !viewModel.showAlert {
                        coordinator.resetSelectedPath()
                        try? await Task.sleep(for: .milliseconds(250))
                        coordinator.setSelectedTab(to: .installedListV2)
                        try? await Task.sleep(for: .milliseconds(250))
                        coordinator.appendToSelectedPath(NavigationDestination.installedListDetailView(installedList))
                    }
                }
            }
        default:
            fatalError("[ERROR] Unhandled action argument: \(action)")
        }
    }
}
