//
//  InstalledListRoomDetailsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/25/26.
//

import SwiftUI

struct InstalledListRoomDetailsView: View {
    @State var viewModel: InstalledListRoomDetailsViewModel
    @Environment(NavigationCoordinator.self) private var coordinator
    @State var itemToRemove: ItemV2? = nil

    init(viewModel: InstalledListRoomDetailsViewModel) {
        self.viewModel = viewModel
    }

    // MARK: State Variables
    @State private var showAddItemsSheet: Bool = false
    @State private var showSelectStorageSheet: Bool = false

    // MARK: Body

    var body: some View {
        VStack(spacing: 16) {
            TopBar
                .frameHorizontalPadding()

            ScrollView {
                VStack(spacing: 16) {
                    RoomImages

                    HStack(spacing: 0) {
                        SmallCTA(type: .secondary, leadingIcon: SFSymbols.arrowCounterclockwise, text: "Refresh") {
                            viewModel.refreshRoom()
                        }

                        Spacer()

                        if !viewModel.uninstalled {
                            SmallCTA(type: .red, leadingIcon: SFSymbols.plus, text: "Add Items") {
                                showAddItemsSheet = true
                            }
                        }
                    }

                    RoomItemList
                }
                .frameHorizontalPadding()
            }
        }
        .sheet(isPresented: $showAddItemsSheet) {
            AddItemsToRoomSheet
        }
        .staleWriteAlert($viewModel.staleWriteError)
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .sheet(isPresented: $showSelectStorageSheet) {
            SelectDocumentSheet(
                title: "Select Storage Location",
                documents: viewModel.availableStorageLocations,
                refreshAction: { Task { await viewModel.fetchAvailableStorageLocations() } },
                action: handleAction(_:)
            )
            .task { await viewModel.fetchAvailableStorageLocations() }
        }
        .onAppear {
            viewModel.startListening()
        }
        .toolbar(.hidden)
        .frameTop()
        .frameHorizontalPadding()
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Top Bar

    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton()
            }, header: {
                VStack(alignment: .center, spacing: 2) {
                    Text("Room")
                        .font(.caption)
                        .foregroundColor(.red)
                        .bold()
                    (
                        Text(viewModel.roomState.displayName)
                            .bold()
                        +
                        Text(viewModel.roomState.squareFootage.map { " · \($0) sq ft" } ?? "")
                            .foregroundColor(.secondary)
                    )
                }
            }, trailingView: {
                EmptyView()
            }
        )
    }

    // MARK: - Room Images
    private var RoomImages: some View {
        HStack(spacing: 8) {
            VStack(spacing: 8) {
                Text("Before")
                    .font(.caption2)
                RoomImage(viewModel.roomState.beforeImage, isBefore: true)
            }
            VStack(spacing: 8) {
                Text("After")
                    .font(.caption2)
                RoomImage(viewModel.roomState.afterImage, isBefore: false)
            }
        }
    }

    /// An uninstalled list is a record, so its photos can be viewed but not replaced.
    @ViewBuilder
    private func RoomImage(_ image: RDImage?, isBefore: Bool) -> some View {
        if viewModel.uninstalled {
            ImageView(image: image)
                .frame(Constants.Image.detail)
        } else {
            ImageEditor(image: image) { result in
                handleImageAction(result, isBefore: isBefore)
            }
                .frame(Constants.Image.detail)
        }
    }

    // MARK: - Room Item List

    private var RoomItemList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.items, id: \.self) { item in
                ItemListItemView(
                    item: item,
                    style: viewModel.uninstalled ? .display : .listRoom,
                    action: handleAction(_:)
                )
                .padding(.horizontal, 4)
            }
        }
    }

    private func handleAction(_ action: Any?) {
        switch action {
        case let storageAction as SelectDocumentSheetAction<StorageLocation>:
            guard let item = itemToRemove,
                  case .selected(let storageLocation) = storageAction else { return }
            Task {
                await viewModel.removeItemToStorage(item: item, storageLocation: storageLocation)
                itemToRemove = nil
            }
        case let itemAction as ItemListItemAction:
            switch itemAction {
            case .removeItem(let item):
                itemToRemove = item
                showSelectStorageSheet = true
            case .navigate(let item):
                coordinator.appendToSelectedPath(
                    NavigationDestination.installedListItemDetailView(
                        item: item,
                        room: viewModel.roomState,
                        uninstalled: viewModel.uninstalled
                    )
                )
            default:
                return
            }
        default:
            return
        }
    }

    private func handleImageAction(_ actionArgument: Any?, isBefore: Bool) {
        guard let action = actionArgument else { return }
        switch action {
        case let imageAction as ImageEditorAction:
            Task {
                await viewModel.updateRoomImage(imageAction, isBefore: isBefore)
            }
        default:
            print("[ERROR] Untracked Action in InstalledListRoomDetailsView: \(action)")
        }
    }
}

// MARK: - AddItemsToRoomSheet
private extension InstalledListRoomDetailsView {
    var AddItemsToRoomSheet: some View {
        AddItemToDocumentSheetV2(
            destination: .room(viewModel.roomState, listType: InstalledListV2.listType),
            defaultFilters: [
                "\(ItemV2.CodingKeys.location.rawValue).\(DocumentLocation.CodingKeys.status.rawValue)": LocationStatus.inStorage.rawValue,
                ItemV2.CodingKeys.essentialGroupId.rawValue: NSNull() as AnyHashable
            ]
        )
    }
}
