//
//  UninstallInstalledListSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import SwiftUI

enum UninstallItemAction {
    case toggleItem(itemId: String)
    case unassign(itemId: String)
    case toggleEssentials
    case unassignEssentials
}

struct UninstallInstalledListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator.self) private var coordinator
    @State private var viewModel: UninstallInstalledListSheetViewModel

    init(viewModel: UninstallInstalledListSheetViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 16) {
            TopBar

            if viewModel.isReadOnly, !viewModel.isSessionComplete {
                ReadOnlyBanner
            }

            ItemListContent

            Spacer(minLength: 0)

            if viewModel.selectionCount > 0 {
                SelectionBar
            }
            
            if viewModel.isOwner {
                RDButton(
                    variant: .red,
                    size: .default,
                    label: "Confirm Uninstall",
                    disabled: !viewModel.allAssigned
                ) {
                    viewModel.showConfirmSheet = true
                }
            }

        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .toolbar(.hidden)
        .task {
            await viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("Ok", role: .cancel) {
                // The alert is presented from this cover, so dismissing has to
                // wait for acknowledgement or the message is never read.
                if viewModel.sessionEndedByOtherUser {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $viewModel.showDestinationSheet) {
            UninstallDestinationSheet(
                selectedItems: viewModel.selectedItems,
                warehouses: viewModel.warehouses,
                copyLabel: viewModel.copySectionTitle,
                selectedCopyAddress: viewModel.copyListAddress,
                roomNames: viewModel.rooms.map(\.displayName),
                action: handleAction
            )
        }
        .sheet(isPresented: $viewModel.showConfirmSheet) {
            ConfirmUninstallSheet(summary: viewModel.confirmUninstallSummary, action: handleAction)
        }
    }
}

private extension UninstallInstalledListSheet {

    // MARK: TopBar

    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton(icon: SFSymbols.xmark)
            },
            header: {
                (
                    Text("Uninstalling: ")
                        .foregroundStyle(.red)
                        .bold()
                    +
                    Text(viewModel.installedListState.displayName)
                )
            },
            trailingView: {
                RDButton(
                    variant: .red,
                    size: .icon,
                    leadingIcon: SFSymbols.arrowCounterclockwise
                ) {
                    viewModel.refreshItems()
                }
                .clipShape(.circle)
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

            Text("View only — someone is uninstalling this list")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            RDButton(variant: .red, size: .sm, label: "Take Over") {
                Task { await viewModel.takeoverSession() }
            }
        }
    }

    // MARK: ItemListContent

    @ViewBuilder
    var ItemListContent: some View {
        if viewModel.isLoading && viewModel.rooms.isEmpty {
            ProgressView()
                .tint(.red)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            ItemList
        }
    }

    var ItemList: some View {
        ScrollView {
            LazyVStack(spacing: 8, pinnedViews: .sectionHeaders) {
                if viewModel.essentialsGroupState != nil {
                    Section {
                        EssentialsGroupRow
                    } header: {
                        UninstallSectionHeader(title: "Essentials")
                    }
                }

                Section {
                    UnassignedRoomGroups
                } header: {
                    UninstallSectionHeader(
                        title: "Unassigned",
                        count: viewModel.unassignedItemsByRoom.reduce(0) { $0 + $1.items.count }
                    )
                }

                StorageSection

                if viewModel.showCopySection {
                    CopySection
                }

                if viewModel.showExistingSection {
                    ExistingListSection
                }
            }
        }
    }

    // MARK: UnassignedRoomGroups

    /// Nothing has moved yet, so unassigned items are still grouped by the
    /// room they're physically in.
    var UnassignedRoomGroups: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.unassignedItemsByRoom, id: \.room.id) { entry in
                RoomListItemView(room: entry.room, itemCount: entry.items.count, style: .installingPullList, action: handleAction) {
                    LazyVStack(spacing: 8) {
                        ForEach(entry.items) { item in
                            SelectableItemRow(item, room: entry.room)
                        }
                    }
                }
                .padding(4)
            }
        }
    }

    // MARK: Destination sections

    /// Storage is always offered; the other two only exist once the user has
    /// set them up, so an empty screen shows one destination rather than three.
    var StorageSection: some View {
        Section {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.storageGroups, id: \.warehouseId) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        // Only worth naming the warehouse when items have been
                        // split across more than one.
                        if viewModel.storageGroups.count > 1 {
                            Text(group.warehouse)
                                .font(.subheadline)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        AssignedItems(group.items)
                    }
                }
            }
        } header: {
            UninstallSectionHeader(title: "Storage", count: viewModel.storageItemCount)
        }
    }

    var CopySection: some View {
        Section {
            AssignedItems(viewModel.copyItems)
        } header: {
            UninstallSectionHeader(
                title: viewModel.copySectionTitle,
                subtitle: viewModel.copySectionSubtitle,
                count: viewModel.copyItems.count
            )
        }
    }

    var ExistingListSection: some View {
        Section {
            AssignedItems(viewModel.existingListItems)
        } header: {
            UninstallSectionHeader(
                title: viewModel.existingSectionTitle,
                count: viewModel.existingListItems.count
            )
        }
    }

    // MARK: AssignedItems

    func AssignedItems(_ entries: [(item: ItemV2, room: RoomV2)]) -> some View {
        UninstallAssignedItemsList(entries: entries) { item in
            if viewModel.isOwner {
                RDButton(
                    variant: .default,
                    size: .icon,
                    leadingIcon: SFSymbols.arrowUturnBackward
                ) {
                    handleAction(UninstallItemAction.unassign(itemId: item.id))
                }
            }
        }
    }

    // MARK: EssentialsGroupRow

    @ViewBuilder
    var EssentialsGroupRow: some View {
        if let group = viewModel.essentialsGroupState {
            UninstallEssentialsSummaryView(
                group: group,
                items: viewModel.essentialsItems,
                accessories: viewModel.essentialsAccessories,
                destinationLabel: viewModel.essentialsDestinationLabel?.title,
                destinationSubtitle: viewModel.essentialsDestinationLabel?.subtitle
            ) {
                if viewModel.isOwner {
                    if viewModel.essentialsDestinationLabel != nil {
                        RDButton(
                            variant: .default,
                            size: .icon,
                            leadingIcon: SFSymbols.arrowUturnBackward
                        ) {
                            handleAction(UninstallItemAction.unassignEssentials)
                        }
                    } else {
                        Button {
                            handleAction(UninstallItemAction.toggleEssentials)
                        } label: {
                            Image(systemName: viewModel.essentialsSelected
                                  ? SFSymbols.checkmarkCircleFill : SFSymbols.circle)
                                .foregroundStyle(viewModel.essentialsSelected ? .red : .gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: SelectableItemRow

    /// `ItemListItemView` renders its own selection circle when handed an
    /// action. The surrounding tap gesture makes the whole row a target too,
    /// per the design's "tap rows to add or remove".
    func SelectableItemRow(_ item: ItemV2, room: RoomV2) -> some View {
        ItemListItemView(
            item: item,
            style: .installation(room: room),
            isSelected: viewModel.isSelected(item.id)
        ) { _ in
            handleAction(UninstallItemAction.toggleItem(itemId: item.id))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleAction(UninstallItemAction.toggleItem(itemId: item.id))
        }
        .allowsHitTesting(viewModel.isOwner)
    }

    // MARK: SelectionBar

    var SelectionBar: some View {
        HStack(spacing: 12) {
            Text("\(viewModel.selectionCount) selected")
                .font(.subheadline)

            Spacer()

            RDButton(variant: .ghost, size: .sm, label: "Clear") {
                viewModel.clearSelection()
            }

            RDButton(variant: .red, size: .sm, label: "Send to…") {
                viewModel.showDestinationSheet = true
            }
        }
    }
}

// MARK: - Handle Action

private extension UninstallInstalledListSheet {
    func handleAction(_ actionArgument: Any?) {
        switch actionArgument {
        case let action as UninstallItemAction:
            switch action {
            case .toggleItem(let itemId):
                viewModel.toggleSelection(itemId)
            case .unassign(let itemId):
                Task { await viewModel.unassign(itemId: itemId) }
            case .toggleEssentials:
                viewModel.toggleEssentialsSelection()
            case .unassignEssentials:
                Task { await viewModel.unassignEssentials() }
            }

        case let action as RoomListItemViewAction:
            switch action {
            case .refreshRoom(let roomId):
                viewModel.refreshRoom(roomId)
            case .navigate:
                // No room-details navigation while uninstalling — the room's
                // add/remove actions would race the session's own writes.
                return
            }

        case is ConfirmUninstallSheetAction:
            Task { @MainActor in
                guard await viewModel.commitUninstall() else { return }
                // Close the cover, then pop the (now uninstalled) details view.
                dismiss()
                try? await Task.sleep(for: .milliseconds(250))
                coordinator.resetSelectedPath()
            }

        case let action as UninstallDestinationSheetAction:
            switch action {
            case .chooseWarehouse(let warehouseId):
                Task { @MainActor in
                    await viewModel.assignSelection(
                        to: UninstallDestination(type: .warehouse, locationId: warehouseId)
                    )
                    viewModel.showDestinationSheet = false
                }

            case .selectCopyAddress(let address):
                Task { @MainActor in
                    await viewModel.setCopyAddress(address)
                }

            case .chooseCopy:
                Task { @MainActor in
                    // Unreachable unless the address write hasn't landed yet —
                    // the send button is gated on it.
                    guard let destination = viewModel.copyDestination() else { return }
                    await viewModel.assignSelection(to: destination)
                    viewModel.showDestinationSheet = false
                }

            case .chooseExistingList(let list):
                Task { @MainActor in
                    guard let destination = await viewModel.existingListDestination(list) else { return }
                    await viewModel.assignSelection(to: destination)
                    viewModel.showDestinationSheet = false
                }
            }

        default:
            break
        }
    }
}
