//
//  InstalledListItemDetailsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/25/26.
//

import SwiftUI

struct InstalledListItemDetailsView: View {
    @Environment(\.dismiss) private var dismiss

    @State var viewModel: InstalledListItemDetailsViewModel

    @State private var showQRCodeSheet: Bool = false
    @State private var showSelectStorageSheet: Bool = false

    init(viewModel: InstalledListItemDetailsViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar
                    .frameHorizontalPadding()

                ScrollView {
                    VStack(spacing: 12) {
                        PrimaryImageView(image: viewModel.itemState.primaryImage)

                        ItemDetails

                        ItemDetailSection(
                            item: viewModel.itemState,
                            essentialsGroup: viewModel.essentialsGroup
                        )
                        .task { await viewModel.loadEssentialsGroup() }
                    }
                    .padding(.top, 4)
                    .frameHorizontalPadding()
                }

                if !viewModel.uninstalled {
                    Footer()
                        .frameHorizontalPadding()
                }
            }
            .fullScreenCover(isPresented: $showQRCodeSheet) {
                ItemV2LabelView(item: viewModel.itemState)
            }
            .sheet(isPresented: $viewModel.showMoveItemSheet) {
                SelectDocumentSheet(
                    title: "Other Rooms",
                    documents: viewModel.rooms.filter { $0.id != viewModel.room.id },
                    action: handleAction(_:)
                )
                .task { await viewModel.fetchRoomsForMove() }
            }
            .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) {
                    viewModel.alertMessage = ""
                    dismiss()
                }
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
            .frameTop()
            .frameBottomPadding()
            .toolbar(.hidden)
            .fullScreenCover(isPresented: $viewModel.showQRCode) {
                ItemV2LabelView(item: viewModel.itemState)
            }
        }
    }

    // MARK: - Action Handling

    private func handleAction(_ action: Any?) {
        guard let action else { return }
        switch action {
        case let sheetAction as SelectDocumentSheetAction<RoomV2>:
            switch sheetAction {
            case .selected(let newRoom):
                Task { await viewModel.moveItemToNewRoom(newRoom: newRoom) }
            default:
                break
            }
        case let storageAction as SelectDocumentSheetAction<StorageLocation>:
            switch storageAction {
            case .selected(let storageLocation):
                Task {
                    let success = await viewModel.removeItemToStorage(storageLocation: storageLocation)
                    if success { dismiss() }
                }
            default:
                break
            }
        default:
            break
        }
    }

    // MARK: - Top Bar

    private var TopBar: some View {
        TopAppBar(leadingView: {
            BackButton()
        }, header: {
            HStack(spacing: 0) {
                Text("Item: ")
                    .bold()
                    .foregroundColor(.red)

                Text(viewModel.itemState.displayName)
            }
        }, trailingView: {
            RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.qrcode) {
                showQRCodeSheet = true
            }
            .clipShape(.circle)
        })
    }

    // MARK: - Item Details

    private var ItemDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.itemState.location.status == .inInstalledList {
                HStack(alignment: .center, spacing: 0) {
                    Text("Location: ")
                        .foregroundColor(.red)
                        .bold()

                    if let address = viewModel.installedList?.address.getStreetAddress() ?? viewModel.installedList?.address.formattedAddress {
                        Text(address)
                    } else {
                        Text("Loading...")
                            .task {
                                await viewModel.fetchInstalledListForLocation()
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(Constants.CornerRadius.medium)
    }

    // MARK: - Footer

    @ViewBuilder
    private func Footer() -> some View {
        HStack(spacing: 12) {
            RDButton(variant: .default, size: .default, leadingIcon: SFSymbols.arrowUturnBackward, label: "Move to Other Room", fullWidth: true, font: .caption2) {
                viewModel.showMoveItemSheet = true
            }

            RDButton(variant: .red, size: .default, leadingIcon: SFSymbols.trash, label: "Remove from \(viewModel.room.displayName)", fullWidth: true, font: .caption2) {
                showSelectStorageSheet = true
            }
        }
    }
}
