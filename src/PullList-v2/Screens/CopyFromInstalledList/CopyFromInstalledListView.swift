//
//  CopyFromInstalledListView.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/29/26.
//

import SwiftUI

/// Step two of copying: choose where the copy is headed, then claim whichever of
/// the source list's items are still in storage.
struct CopyFromInstalledListView: View {
    @State var viewModel: CopyFromInstalledListViewModel

    /// Dismisses the whole cover, not just this screen.
    let onFinished: () -> Void

    /// `AddressSheet` writes into a binding and reports nothing back, so the
    /// draft is observed and promoted once it's populated.
    @State private var draftAddress: Address = Address()
    @State private var draftAddressId: String = ""
    @State private var showAddressSheet: Bool = false
    @State private var showConfirmation: Bool = false

    /// Set when the commit claimed less than the preview promised.
    @State private var droppedMessage: String? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        DatesSection
                        ClientSection
                        SquareFootageSection
                        RoomsSection
                        EssentialsSection
                    }
                }
                .scrollIndicators(.hidden)

                Footer
            }
            .frameTop()
            .frameHorizontalPadding()
            .toolbar(.hidden)

            if viewModel.isCreating {
                FullScreenProgressView(label: "Creating Pull List...")
            }
        }
        .task { await viewModel.load() }
        .sheet(isPresented: $showAddressSheet) {
            AddressSheet(selectedAddress: $draftAddress, addressId: $draftAddressId)
        }
        .onChange(of: draftAddress) {
            guard draftAddress.isInitialized() else { return }
            viewModel.address = draftAddress
        }
        .confirmationDialog(
            viewModel.confirmationMessage,
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Create Pull List") { create() }
            Button("Cancel", role: .cancel) {}
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert(
            droppedMessage ?? "",
            isPresented: Binding(
                get: { droppedMessage != nil },
                set: { if !$0 { droppedMessage = nil } }
            )
        ) {
            Button("OK") { onFinished() }
        }
    }

    // MARK: - TopBar

    /// The copy needs a destination before anything can be claimed, so the address
    /// lives in the header and the create button stays disabled until it's set.
    private var TopBar: some View {
        TopAppBar(
            leadingView: { BackButton() },
            header: {
                RDButton(
                    variant: .outline,
                    size: .default,
                    leadingIcon: SFSymbols.mapPinAndEllipse,
                    label: viewModel.address.map { $0.getStreetAddress() ?? $0.formattedAddress } ?? "Enter Address"
                ) {
                    showAddressSheet = true
                }
            },
            trailingView: { Spacer().frame(width: 32) }
        )
    }

    // MARK: - Dates

    private var DatesSection: some View {
        VStack(spacing: 12) {
            DatePicker(
                selection: $viewModel.installDate,
                displayedComponents: [.date]
            ) {
                Text("Install Date:")
                    .foregroundColor(.secondary)
                    .bold()
            }

            DatePicker(
                selection: $viewModel.uninstallDate,
                displayedComponents: [.date]
            ) {
                Text("Uninstall Date:")
                    .foregroundColor(.red)
                    .bold()
            }
        }
    }

    // MARK: - Client

    private var ClientSection: some View {
        HStack {
            Text("Client:")
            TextField("", text: $viewModel.clientId)
                .padding(6)
                .background(Color(.systemGray5))
                .cornerRadius(Constants.CornerRadius.medium)
        }
    }

    // MARK: - Square Footage

    private var SquareFootageSection: some View {
        HStack {
            Text("Square Feet:")
            TextField("Optional", text: $viewModel.squareFootage)
                .keyboardType(.decimalPad)
                .padding(6)
                .background(Color(.systemGray5))
                .cornerRadius(Constants.CornerRadius.medium)
        }
    }

    // MARK: - Rooms

    @ViewBuilder
    private var RoomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rooms:")
                .font(.headline)
                .foregroundColor(.red)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.rooms) { room in
                        RoomRow(room)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func RoomRow(_ room: RoomV2) -> some View {
        let items = viewModel.itemsByRoom[room.id] ?? []

        ExpandableSectionView(
            style: .copyRoom(
                room: room,
                copyableCount: items.filter { viewModel.isCopyable($0) }.count,
                itemCount: items.count
            ),
            isExpanded: false
        ) {
            VStack(spacing: 8) {
                ForEach(items) { item in
                    SourceItemRow(item)
                }
            }
        }
    }

    /// Items that can't be copied stay visible so it's clear what the new list is missing and why.
    @ViewBuilder
    private func SourceItemRow(_ item: ItemV2) -> some View {
        let reason = viewModel.unavailableReason(for: item)

        VStack(alignment: .leading, spacing: 2) {
            ItemListItemView(item: item, style: .display)
                .opacity(reason == nil ? 1 : 0.5)

            if let reason {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.leading, 8)
            }
        }
    }

    // MARK: - Essentials

    @ViewBuilder
    private var EssentialsSection: some View {
        if let group = viewModel.essentialsGroup {
            VStack(alignment: .leading, spacing: 12) {
                Text("Essentials:")
                    .font(.headline)
                    .foregroundColor(.red)

                UninstallEssentialsSummaryView(
                    group: group,
                    items: viewModel.essentialsItems,
                    accessories: viewModel.essentialsAccessories,
                    destinationLabel: viewModel.isEssentialsGroupCopyable ? "Available" : "Unavailable"
                )

                // The group moves as one unit, so a single unavailable member blocks the whole set.
                if !viewModel.isEssentialsGroupCopyable {
                    Text("The group, its items, and its accessories must all be in storage.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Footer

    private var Footer: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.copyableItemCount) of \(viewModel.totalItemCount) items available")
                .font(.footnote)
                .foregroundStyle(.secondary)

            RDButton(
                variant: .red,
                size: .default,
                leadingIcon: SFSymbols.plus,
                label: "Create Pull List",
                fullWidth: true,
                disabled: !viewModel.canCreate
            ) {
                showConfirmation = true
            }
        }
        .padding(.bottom, 16)
    }

    // MARK: - Create

    private func create() {
        Task {
            guard let outcome = await viewModel.createCopy() else { return }

            if let message = viewModel.droppedMessage(for: outcome) {
                droppedMessage = message
            } else {
                onFinished()
            }
        }
    }
}
