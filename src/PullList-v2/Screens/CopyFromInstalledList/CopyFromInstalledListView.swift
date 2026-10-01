//
//  CopyFromInstalledListView.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/29/26.
//

import SwiftUI

/// Step two of copying: choose where the copy is headed, then claim whichever of
/// the source list's items are still in storage.
///
/// Intentionally unstyled — structure only.
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
        VStack(spacing: 12) {
            TopBar

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AddressSection
                    DatesSection
                    ClientSection
                    SquareFootageSection
                    RoomsSection
                    EssentialsSection
                }
            }

            Footer
        }
        .frameTop()
        .frameHorizontalPadding()
        .toolbar(.hidden)
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

    private var TopBar: some View {
        TopAppBar(
            leadingView: { BackButton() },
            header: { Text("Copy of \(viewModel.installedList.displayName)") },
            trailingView: { Spacer().frame(width: 32) }
        )
    }

    // MARK: - Address

    /// The copy needs a destination before anything can be claimed, so this gate
    /// comes first and the create button stays disabled until it's satisfied.
    @ViewBuilder
    private var AddressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Address")
                .font(.headline)

            if let address = viewModel.address {
                Text(address.getStreetAddress() ?? address.formattedAddress)
                Button("Change") { showAddressSheet = true }
            } else {
                Button("Select Address") { showAddressSheet = true }
            }
        }
    }

    // MARK: - Dates

    private var DatesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            DatePicker(
                selection: $viewModel.installDate,
                displayedComponents: [.date]
            ) {
                Text("Install Date:")
            }

            DatePicker(
                selection: $viewModel.uninstallDate,
                displayedComponents: [.date]
            ) {
                Text("Uninstall Date:")
            }
        }
    }

    // MARK: - Client

    private var ClientSection: some View {
        HStack {
            Text("Client:")
            TextField("", text: $viewModel.clientId)
        }
    }

    // MARK: - Square Footage

    private var SquareFootageSection: some View {
        HStack {
            Text("Sq Ft:")
            TextField("Optional", text: $viewModel.squareFootage)
                .keyboardType(.decimalPad)
        }
    }

    // MARK: - Rooms

    @ViewBuilder
    private var RoomsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rooms")
                .font(.headline)

            if viewModel.isLoading {
                ProgressView()
            } else {
                ForEach(viewModel.rooms) { room in
                    RoomRow(room)
                }
            }
        }
    }

    @ViewBuilder
    private func RoomRow(_ room: RoomV2) -> some View {
        let items = viewModel.itemsByRoom[room.id] ?? []
        let copyable = items.filter { viewModel.isCopyable($0) }.count

        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(room.displayName)
                Spacer()
                Text("\(copyable) / \(items.count)")
            }

            ForEach(items) { item in
                HStack {
                    Text(item.displayName)
                    Spacer()
                    if let reason = viewModel.unavailableReason(for: item) {
                        Text(reason)
                    }
                }
                .font(.caption)
            }
        }
    }

    // MARK: - Essentials

    @ViewBuilder
    private var EssentialsSection: some View {
        if let group = viewModel.essentialsGroup {
            VStack(alignment: .leading, spacing: 4) {
                Text("Essentials")
                    .font(.headline)

                HStack {
                    Text("\(group.emoji) \(group.displayName)")
                    Spacer()
                    Text(viewModel.isEssentialsGroupCopyable ? "Available" : "Unavailable")
                }

                // The group moves as one unit, so it's worth saying that a single
                // unavailable member is what blocks the whole set.
                if !viewModel.isEssentialsGroupCopyable {
                    Text("The group, its items, and its accessories must all be in storage.")
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Footer

    private var Footer: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.copyableItemCount) of \(viewModel.totalItemCount) items available")

            RDButton(
                variant: .red,
                leadingIcon: SFSymbols.plus,
                label: "Create Pull List",
                fullWidth: true,
                disabled: !viewModel.canCreate
            ) {
                showConfirmation = true
            }
        }
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
