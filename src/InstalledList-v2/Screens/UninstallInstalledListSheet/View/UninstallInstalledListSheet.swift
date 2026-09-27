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

            ItemListContent

            Spacer(minLength: 0)

            if viewModel.selectionCount > 0 {
                SelectionBar
            }
            
            RDButton(
                variant: .red,
                size: .default,
                label: "Confirm Uninstall",
                disabled: !viewModel.allAssigned
            ) {
                viewModel.showConfirmSheet = true
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
                Section {
                    UnassignedRoomGroups
                } header: {
                    SectionHeader(
                        "Unassigned",
                        count: viewModel.unassignedItemsByRoom.reduce(0) { $0 + $1.items.count }
                    )
                }

                Section {
                    AssignedDestinationGroups
                } header: {
                    SectionHeader("Assigned", count: viewModel.assignedItemCount)
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

    // MARK: AssignedDestinationGroups

    /// Once assigned, room of origin is no longer the organizing question —
    /// items are flattened and grouped by where they're headed instead.
    var AssignedDestinationGroups: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.assignedItemsByDestination, id: \.label) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(group.label)
                            .font(.subheadline)
                            .bold()

                        Spacer()

                        Text("(\(group.items.count))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(group.items, id: \.item.id) { entry in
                        AssignedItemRow(entry.item, room: entry.room)
                    }   
                }
            }
        }
    }

    // MARK: SectionHeader

    func SectionHeader(_ title: String, count: Int? = nil) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.red)

            Spacer()

            if let count = count {
                Text("(\(count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .background(Color(.systemBackground))
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
    }

    // MARK: AssignedItemRow

    /// No action passed, so no selection circle — an assigned item is changed
    /// by reverting it, not by re-selecting it.
    func AssignedItemRow(_ item: ItemV2, room: RoomV2) -> some View {
        HStack(spacing: 8) {
            ItemListItemView(item: item, style: .installation(room: room))

            VStack(alignment: .trailing, spacing: 4) {
                if let label = viewModel.destinationLabel(for: item.id) {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

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
            }

        default:
            break
        }
    }
}
