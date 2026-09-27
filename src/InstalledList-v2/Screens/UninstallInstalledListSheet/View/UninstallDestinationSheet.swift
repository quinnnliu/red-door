//
//  UninstallDestinationSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import SwiftUI

enum UninstallDestinationSheetAction {
    case chooseWarehouse(warehouseId: String)
    case chooseCopy
}

/// Warehouse and new-list destinations. The "Existing" segment arrives with
/// the existing-pull-list phase.
struct UninstallDestinationSheet: View {
    let selectedItems: [ItemV2]
    let warehouses: [WarehouseV2]
    let copyLabel: String
    let roomNames: [String]
    let action: (Any?) -> Void

    private enum Segment: Int {
        case warehouse
        case newList
    }

    @State private var segment: Segment = .warehouse

    var body: some View {
        VStack(spacing: 16) {
            DragIndicator()

            Header

            SelectedItemsStrip

            DestinationPicker

            ScrollView {
                switch segment {
                case .warehouse: WarehouseOptions
                case .newList: NewListOption
                }
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

    // MARK: DestinationPicker

    var DestinationPicker: some View {
        SegmentedPicker(
            segments: [
                .init("Warehouse", selectedColor: .gray) { segment = .warehouse },
                .init("New list", selectedColor: .red) { segment = .newList }
            ],
            selectedIndex: segment.rawValue
        )
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

    // MARK: NewListOption

    var NewListOption: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                action(UninstallDestinationSheetAction.chooseCopy)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: SFSymbols.plus)
                        .foregroundStyle(.red)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(copyLabel)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Inherits client and dates")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rooms copied 1:1")
                    .font(.subheadline)
                    .bold()

                Text("Items keep their source rooms (\(roomNames.joined(separator: ", "))).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
