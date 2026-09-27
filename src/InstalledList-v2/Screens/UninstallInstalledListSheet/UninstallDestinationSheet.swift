//
//  UninstallDestinationSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import SwiftUI

enum UninstallDestinationSheetAction {
    case chooseWarehouse(warehouseId: String)
}

/// Warehouse-only for now. The segmented picker and the "New list" / "Existing"
/// options arrive with the later destination phases.
struct UninstallDestinationSheet: View {
    let selectedItems: [ItemV2]
    let warehouses: [WarehouseV2]
    let action: (Any?) -> Void

    var body: some View {
        VStack(spacing: 16) {
            DragIndicator()

            Header

            SelectedItemsStrip

            ScrollView {
                WarehouseOptions
            }

            Spacer(minLength: 0)
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .presentationDetents([.medium, .large])
    }
}

private extension UninstallDestinationSheet {

    // MARK: Header

    var Header: some View {
        VStack(spacing: 4) {
            Text("Send \(selectedItems.count) \(selectedItems.count == 1 ? "item" : "items") to")
                .font(.headline)
                .foregroundStyle(.red)

            Text("Pick a destination — items move together.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: SelectedItemsStrip

    var SelectedItemsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedItems, id: \.id) { item in
                    HStack(spacing: 6) {
                        PrimaryImageView(
                            image: item.primaryImage,
                            size: Constants.Image.listItemDefault,
                            isExpandable: false
                        )

                        Text(item.displayName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    // MARK: WarehouseOptions

    var WarehouseOptions: some View {
        LazyVStack(spacing: 8) {
            ForEach(warehouses, id: \.id) { warehouse in
                Button {
                    action(UninstallDestinationSheetAction.chooseWarehouse(warehouseId: warehouse.id))
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: SFSymbols.shippingbox)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(warehouse.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(warehouse.address.getStreetAddress() ?? warehouse.address.formattedAddress)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
