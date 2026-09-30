//
//  StorageLocationOptionsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/23/26.
//

import SwiftUI

struct StorageLocationOptionsView: View {
    @State private var viewModel = StorageLocationOptionsViewModel()

    var body: some View {
        StorageSection()
            .task {
                if viewModel.storageLocations.isEmpty {
                    await viewModel.loadStorageLocations()
                }
            }
            .sheet(isPresented: $viewModel.showAddressSheet) {
                AddressSheet(selectedAddress: $viewModel.newStorageLocation.address, addressId: $viewModel.newStorageLocation.id)
                    .onDisappear {
                        if viewModel.newStorageLocation.address.isInitialized() {
                            viewModel.showStorageLocationNameAlert = true
                        }
                    }
            }
            .alert(viewModel.storageLocationAddressExists ? "Storage location with that address already exists." : "Enter Storage Location Name", isPresented: $viewModel.showStorageLocationNameAlert) {
                StorageLocationNameAlertContent()
            }
            .alert("Confirm Delete", isPresented: $viewModel.showStorageLocationDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    viewModel.showStorageLocationDeleteAlert = false
                }
            } message: {
                Text("Reach out to administrator to delete this storage location permanently.")
            }
    }

    // MARK: Storage Section

    @ViewBuilder
    private func StorageSection() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("Storage Locations")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if viewModel.showStorageLocationSection {
                    RDButton(variant: viewModel.editingStorageLocations ? .red : .outline, size: .icon, leadingIcon: "square.and.pencil", fullWidth: false) {
                        viewModel.editingStorageLocations.toggle()
                    }
                }

                RDButton(variant: .outline, size: .icon, leadingIcon: viewModel.showStorageLocationSection ? "chevron.up" : "chevron.down", fullWidth: false) {
                    withAnimation(Constants.Animation.snappy) {
                        viewModel.showStorageLocationSection.toggle()
                        viewModel.editingStorageLocations = false
                    }
                }
            }
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)

            if viewModel.showStorageLocationSection {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.storageLocations, id: \.self) { storageLocation in
                        StorageLocationListItem(storageLocation: storageLocation)
                    }

                    if viewModel.editingStorageLocations {
                        RDButton(variant: .secondary, size: .default, leadingIcon: "plus", label: "Add Storage Location", fullWidth: true) {
                            viewModel.resetStorageLocation()
                            viewModel.showAddressSheet = true
                        }
                    }
                }
            }
        }
    }

    // MARK: StorageLocation Name Alert Content

    @ViewBuilder
    private func StorageLocationNameAlertContent() -> some View {
        Group {
            TextField("Storage Location Name", text: $viewModel.storageLocationName)
                .textInputAutocapitalization(.never)

            Button("OK") {
                viewModel.addStorageLocation()
            }.tint(.blue)
        }
    }

    // MARK: StorageLocation List Item

    @ViewBuilder
    private func StorageLocationListItem(storageLocation: StorageLocation) -> some View {
        HStack(spacing: 12) {
            Text(storageLocation.displayName)
                .foregroundColor(.primary)

            (
                Text("\(storageLocation.address.getStreetAddress() ?? ""), ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                +
                Text((storageLocation.address.getCityStateZipcode() ?? ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
            )

            Spacer()

            if viewModel.editingStorageLocations {
                Button {
                    viewModel.showStorageLocationDeleteAlert = true
                } label: {
                    Image(systemName: SFSymbols.trash)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}
