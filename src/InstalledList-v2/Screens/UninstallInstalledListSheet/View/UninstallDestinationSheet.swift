//
//  UninstallDestinationSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import SwiftUI

enum UninstallDestinationSheetAction {
    case chooseWarehouse(warehouseId: String)
    case selectCopyAddress(Address)
    case chooseCopy
    case chooseExistingList(PullListV2)
}

struct UninstallDestinationSheet: View {
    let selectedItems: [ItemV2]
    let warehouses: [WarehouseV2]
    let copyLabel: String
    /// Server truth from the session, so a user who takes the session over
    /// inherits the address instead of being asked to pick again.
    let selectedCopyAddress: Address?
    let roomNames: [String]
    let action: (Any?) -> Void

    /// Drives `AddressSheet` only. The committed choice is whatever came back
    /// from the session as `selectedCopyAddress`.
    @State private var draftAddress: Address
    @State private var draftAddressId: String = ""
    @State private var showAddressSheet: Bool = false

    init(
        selectedItems: [ItemV2],
        warehouses: [WarehouseV2],
        copyLabel: String,
        selectedCopyAddress: Address?,
        roomNames: [String],
        action: @escaping (Any?) -> Void
    ) {
        self.selectedItems = selectedItems
        self.warehouses = warehouses
        self.copyLabel = copyLabel
        self.selectedCopyAddress = selectedCopyAddress
        self.roomNames = roomNames
        self.action = action
        _draftAddress = State(initialValue: selectedCopyAddress ?? Address())
    }

    private enum Segment: Int, CaseIterable, Identifiable {
        case warehouse
        case newList
        case existing

        var title: String {
            switch self {
            case .warehouse: "Warehouse"
            case .newList: "New list"
            case .existing: "Existing"
            }
        }

        var id: String { "\(self)" }
    }

    @State private var segment: Segment = .warehouse

    @State private var pullLists = DocumentListViewModelV2<PullListV2>()
    @State private var didLoadPullLists: Bool = false

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
                case .existing: ExistingListOptions
                }
            }

            Spacer(minLength: 0)
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .presentationDetents([.medium, .large])
        .task(id: segment) {
            guard segment == .existing, !didLoadPullLists else { return }
            didLoadPullLists = true
            await pullLists.refresh()
        }
        .sheet(isPresented: $showAddressSheet) {
            AddressSheet(selectedAddress: $draftAddress, addressId: $draftAddressId)
        }
        // `AddressSheet` dismisses itself and reports nothing back, so the
        // write is driven off the binding it wrote. Does not fire for the seed.
        .onChange(of: draftAddress) {
            guard draftAddress.isInitialized() else { return }
            action(UninstallDestinationSheetAction.selectCopyAddress(draftAddress))
        }
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
        Picker("Destination", selection: $segment) {
            ForEach(Segment.allCases, id: \.self) { segment in
                Text(segment.title).tag(segment)
            }
        }
        .pickerStyle(.segmented)
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

    /// The copy needs somewhere to go before anything can be routed to it, so
    /// the address gate comes first and the send button stays disabled until
    /// the choice has been written to the session.
    var NewListOption: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(copyLabel)
                    .font(.headline)

                Text("Inherits client and dates")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            AddressRow

            RDButton(
                variant: .red,
                leadingIcon: SFSymbols.plus,
                label: "Send to This List",
                fullWidth: true,
                disabled: selectedCopyAddress == nil
            ) {
                action(UninstallDestinationSheetAction.chooseCopy)
            }

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

    // MARK: AddressRow

    @ViewBuilder
    var AddressRow: some View {
        if let address = selectedCopyAddress {
            HStack(spacing: 12) {
                Image(systemName: SFSymbols.mappinAndEllipse)
                    .foregroundStyle(.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(address.getStreetAddress() ?? address.formattedAddress)
                        .font(.subheadline)

                    if let cityStateZip = address.getCityStateZipcode() {
                        Text(cityStateZip)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                RDButton(variant: .outline, size: .sm, label: "Change") {
                    showAddressSheet = true
                }
            }
        } else {
            RDButton(
                variant: .outline,
                leadingIcon: SFSymbols.mappinAndEllipse,
                label: "Select Address",
                fullWidth: true
            ) {
                showAddressSheet = true
            }
        }
    }

    // MARK: ExistingListOptions

    var ExistingListOptions: some View {
        LazyVStack(spacing: 8) {
            ForEach(pullLists.documents, id: \.id) { list in
                Button {
                    action(UninstallDestinationSheetAction.chooseExistingList(list))
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: SFSymbols.pencilAndListClipboard)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(list.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text("\(list.address.getCityStateZipcode() ?? "") · \(list.roomIds.count) rooms")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
            }

            DocumentLoadMoreButton(
                isLoading: pullLists.isLoading,
                hasMore: pullLists.hasMore,
                noMoreLabel: "No more pull lists"
            ) {
                await pullLists.loadMore()
            }
        }
    }
}
