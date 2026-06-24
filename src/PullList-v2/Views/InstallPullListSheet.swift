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
    
    init(list: PullListV2, rooms: [RoomV2] = [], itemsByRoom: [String: [ItemV2]] = [:]) {
        viewModel = InstallPullListSheetViewModel(from: list, rooms: rooms, itemsByRoom: itemsByRoom)
    }

    var body: some View {
        VStack(spacing: 16) {
            TopBar
            
            RoomList
            
            Spacer()
            
            RDButton(variant: .red, size: .default, leadingIcon: SFSymbols.plus, iconBold: true, label: "Create Installed List", fullWidth: true) {
                viewModel.showConfirmSheet = true
            }
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
                Text("Installing: \(viewModel.pullListState.address.getStreetAddress() ?? "loading")")
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
                    InstallPullListRoomListItem(
                        room,
                        items: viewModel.itemsByRoom[room.id] ?? [],
                        installStates: viewModel.itemInstallStates,
                        warehouses: viewModel.warehouses,
                        action: handleAction(_:)
                    )
                }
            }
        }
    }
}

// MARK: RoomPreviewHeader

struct InstallPullListRoomListItem: View {
    @State private var showItems: Bool = false

    let items: [ItemV2]
    let room: RoomV2
    let installStates: [String: (status: LocationStatus, locationId: String)]
    let warehouses: [WarehouseV2]
    let action: (Any?) -> ()

    init(
        _ room: RoomV2,
        items: [ItemV2],
        installStates: [String: (status: LocationStatus, locationId: String)],
        warehouses: [WarehouseV2],
        action: @escaping (Any?) -> ()
    ) {
        self.items = items
        self.room = room
        self.installStates = installStates
        self.warehouses = warehouses
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 8) {
            RoomPreviewHeader(room, itemCount: items.count)
            
            if showItems {
                ItemList(items)
            }
        }
    }
    
    // MARK: RoomPreviewHeader
    
    private func RoomPreviewHeader(_ room: RoomV2, itemCount: Int) -> some View {
        HStack(spacing: 12) {
            Text(room.displayName)
                .font(.headline)
            
            Spacer()
            
            (
                Text("Items: ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                +
                Text("\(itemCount)")
                    .font(.caption)
                    .foregroundColor(.red)
            )
            
            RDButton(
                variant: .default,
                size: .icon,
                leadingIcon: SFSymbols.arrowCounterclockwise
            ) {
                action(InstallPullListRoomAction.refreshRoom(roomId: room.id))
            }
            
            RDButton(
                variant: .outline,
                size: .icon,
                leadingIcon: showItems ? SFSymbols.minus : SFSymbols.plus,
                iconBold: true,
                fullWidth: false,
                disabled: itemCount == 0
            ) {
                showItems.toggle()
            }
            .disabled(items.isEmpty)
        }
    }
    
    // MARK: ItemList
    
    private func ItemList(_ items: [ItemV2]) -> some View {
        LazyVStack(spacing: 8) {
            ForEach(items) { item in
                ItemListItem(item)
            }
        }
    }
    
    // MARK: ItemListItem
    
    private func ItemListItem(_ item: ItemV2) -> some View {
        HStack(spacing: 8) {
            ItemListItemImage(item.primaryImage)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.displayName)
                        .font(.headline)
                    
                    if let label = installStateLabel(item: item) {
                        HStack(spacing: 4) {
                            Text("•")
                            Text(label)
                                .foregroundStyle(.red)
                                .lineLimit(1)
                        }.font(.caption2)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: item.type.icon ?? SFSymbols.ellipsis)
                    Text("•")
                    Text(item.material.title)
                    if let color = item.color.color {
                        Text("•")
                        Image(systemName: SFSymbols.circleFill)
                            .foregroundStyle(color)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            InstallPullListStoragePicker(
                item: item,
                installStates: installStates,
                warehouses: warehouses,
                action: action
            )
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
    
    private func installStateLabel(item: ItemV2) -> String? {
        guard let state = installStates[item.id] else { return nil }
        switch state.status {
        case .inPullList:
                return "\(state.status.displayTitle)"
        case .inStorage:
            guard let name = warehouses.first(where: { $0.id ==
                state.locationId })?.displayName else {
                return nil
            }
            return "Storage: \(name)"
        default:
            return nil
        }
    }
}

// MARK: InstallPullListRoomAction

enum InstallPullListRoomAction {
    case storeItem(itemId: String, warehouseId: String)
    case installItem(itemId: String)
    case refreshRoom(roomId: String)
}

// MARK: handleAction

extension InstallPullListSheet {
    func handleAction(_ actionArgument: Any?) {
        guard let action = actionArgument else { return }
        
        switch action {
        case let roomAction as InstallPullListRoomAction:
            switch roomAction {
            case .installItem(let itemId):
                viewModel.itemInstallStates.updateValue((status: .inInstalledList, locationId: viewModel.pullListState.id), forKey: itemId)
            case .refreshRoom(let roomId):
                viewModel.refreshRoom(roomId)
            case .storeItem(let itemId, let warehouseId):
                viewModel.itemInstallStates.updateValue((status: .inStorage, locationId: warehouseId), forKey: itemId)
            }
        case let confirmAction as ConfirmInstallSheetAction:
            switch confirmAction {
            case .confirm:
                Task { @MainActor in
                    if let installedList = await viewModel.createInstalledList() {
                        if !viewModel.showAlert {
                            coordinator.resetSelectedPath()
                            try? await Task.sleep(for: .milliseconds(250))
                            coordinator.setSelectedTab(to: .installedListV2)
                            try? await Task.sleep(for: .milliseconds(250))
                            coordinator.appendToSelectedPath(NavigationDestination.installedListDetailView(installedList))
                        }
                    }
                }
            }
        default:
            fatalError("[ERROR] Unhandled action argument: \(action)")
        }
    }
}
