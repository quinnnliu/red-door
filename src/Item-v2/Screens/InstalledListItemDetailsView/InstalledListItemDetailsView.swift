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
    @State private var showSelectWarehouseSheet: Bool = false

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

                        ItemDetailSection(item: viewModel.itemState)
                    }
                    .padding(.top, 4)
                    .frameHorizontalPadding()
                }

                Footer()
                    .frameHorizontalPadding()
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
            .sheet(isPresented: $showSelectWarehouseSheet) {
                SelectDocumentSheet(
                    title: "Select Storage Location",
                    documents: viewModel.availableWarehouses,
                    action: handleAction(_:),
                    refreshAction: { Task { await viewModel.fetchAvailableWarehouses() } }
                )
                .task { await viewModel.fetchAvailableWarehouses() }
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
            }
        case let warehouseAction as SelectDocumentSheetAction<WarehouseV2>:
            switch warehouseAction {
            case .selected(let warehouse):
                Task {
                    let success = await viewModel.removeItemToWarehouse(warehouse: warehouse)
                    if success { dismiss() }
                }
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

            HStack(alignment: .center, spacing: 0) {
                Text("ID: ")
                    .foregroundColor(.red)
                    .bold()

                Text(viewModel.itemState.id)
                    .font(.caption)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 4) {
                    Text("Needs Attention: ")
                        .foregroundColor(.red)
                        .bold()

                    Image(systemName: SFSymbols.exclamationmarkTriangleFill)
                        .foregroundColor(viewModel.itemState.attention ? .yellow : .gray)
                }

                if let attentionDescription = viewModel.itemState.attentionDescription, viewModel.itemState.attention {
                    Text(attentionDescription)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }

    // MARK: - Footer

    @ViewBuilder
    private func Footer() -> some View {
        HStack(spacing: 12) {
            RDButton(variant: .default, size: .default, leadingIcon: SFSymbols.arrowUturnBackward, label: "Move to Other Room", fullWidth: true, font: .caption2) {
                viewModel.showMoveItemSheet = true
            }

            RDButton(variant: .red, size: .default, leadingIcon: SFSymbols.trash, label: "Remove from \(viewModel.room.displayName)", fullWidth: true, font: .caption2) {
                showSelectWarehouseSheet = true
            }
        }
    }
}
