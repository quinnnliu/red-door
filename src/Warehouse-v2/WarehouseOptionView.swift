//
//  WarehouseOptionView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/23/26.
//

import SwiftUI

struct WarehouseOptionView: View {
    @State private var viewModel = WarehouseOptionViewModel()

    var body: some View {
        StorageSection()
            .task {
                if viewModel.warehouses.isEmpty {
                    await viewModel.loadWarehouses()
                }
            }
            .sheet(isPresented: $viewModel.showAddressSheet) {
                AddressSheet(selectedAddress: $viewModel.newWarehouse.address, addressId: $viewModel.newWarehouse.id)
                    .onDisappear {
                        if viewModel.newWarehouse.address.isInitialized() {
                            viewModel.showWarehouseNameAlert = true
                        }
                    }
            }
            .alert(viewModel.warehouseAddressExists ? "Warehouse with that address already exists." : "Enter Warehouse Name", isPresented: $viewModel.showWarehouseNameAlert) {
                WarehouseNameAlertContent()
            }
            .alert("Confirm Delete", isPresented: $viewModel.showWarehouseDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    viewModel.showWarehouseDeleteAlert = false
                }
            } message: {
                Text("Reach out to administrator to delete this storage location permanently.")
            }
    }

    // MARK: Warehouse Section

    @ViewBuilder
    private func StorageSection() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("Warehouse Locations")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if viewModel.showWarehouseSection {
                    RDButton(variant: viewModel.editingWarehouses ? .red : .outline, size: .icon, leadingIcon: "square.and.pencil", iconBold: true, fullWidth: false) {
                        viewModel.editingWarehouses.toggle()
                    }
                }

                RDButton(variant: .outline, size: .icon, leadingIcon: viewModel.showWarehouseSection ? "chevron.up" : "chevron.down", iconBold: true, fullWidth: false) {
                    withAnimation(Constants.Animation.snappy) {
                        viewModel.showWarehouseSection.toggle()
                        viewModel.editingWarehouses = false
                    }
                }
            }
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)

            if viewModel.showWarehouseSection {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.warehouses, id: \.self) { warehouse in
                        WarehouseListItem(warehouse: warehouse)
                    }

                    if viewModel.editingWarehouses {
                        RDButton(variant: .secondary, size: .default, leadingIcon: "plus", label: "Add Warehouse", fullWidth: true) {
                            viewModel.resetNewWarehouse()
                            viewModel.showAddressSheet = true
                        }
                    }
                }
            }
        }
    }

    // MARK: Warehouse Name Alert Content

    @ViewBuilder
    private func WarehouseNameAlertContent() -> some View {
        Group {
            TextField("Warehouse Name", text: $viewModel.warehouseName)
                .textInputAutocapitalization(.never)

            Button("OK") {
                viewModel.addWarehouse()
            }.tint(.blue)
        }
    }

    // MARK: Warehouse List Item

    @ViewBuilder
    private func WarehouseListItem(warehouse: WarehouseV2) -> some View {
        HStack(spacing: 12) {
            Text(warehouse.displayName)
                .foregroundColor(.primary)

            (
                Text("\(warehouse.address.getStreetAddress() ?? ""), ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                +
                Text((warehouse.address.getCityStateZipcode() ?? ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
            )

            Spacer()

            if viewModel.editingWarehouses {
                Button {
                    viewModel.showWarehouseDeleteAlert = true
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
