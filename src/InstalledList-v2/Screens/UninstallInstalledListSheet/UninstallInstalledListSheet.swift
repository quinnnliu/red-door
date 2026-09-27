//
//  UninstallInstalledListSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import SwiftUI

struct UninstallInstalledListSheet: View {
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
            Button("Ok", role: .cancel) {}
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
            RoomList
        }
    }

    // MARK: RoomList

    var RoomList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.rooms) { room in
                    let items = viewModel.itemsByRoom[room.id] ?? []
                    RoomListItemView(room: room, itemCount: items.count, style: .installingPullList, action: handleAction) {
                        LazyVStack(spacing: 8) {
                            ForEach(items) { item in
                                ItemListItemView(item: item, style: .installation(room: room))
                            }
                        }
                    }
                    .padding(4)
                }
            }
        }
    }
}

// MARK: Handle Action

private extension UninstallInstalledListSheet {
    func handleAction(_ actionArgument: Any?) {
        guard let action = actionArgument else { return }

        if let roomAction = action as? RoomListItemViewAction {
            switch roomAction {
            case .refreshRoom(let roomId):
                viewModel.refreshRoom(roomId)
            case .navigate:
                // No room-details navigation while uninstalling — the room's
                // add/remove actions would race the session's own writes.
                return
            }
        }
    }
}
