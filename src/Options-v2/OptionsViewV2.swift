//
//  OptionsViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import SwiftUI

struct OptionsViewV2: View {
        // MARK: init Variables
    @Environment(NavigationCoordinator.self) var coordinator
    @State private var warehouseViewModel: WarehouseV2ViewModel = WarehouseV2ViewModel()
    
    @State private var showWarehouseSection: Bool = false
    
        // Editing Warehouses
    @State private var editingWarehouses: Bool = false
    @State private var showAddressSheet: Bool = false
    @State private var newWarehouse: WarehouseV2 = WarehouseV2(displayName: "", address: Address())
    @State private var warehouseName: String = ""
    @State private var showWarehouseNameAlert: Bool = false
    @State private var showWarehouseDeleteAlert: Bool = false
    
    @State private var showProfileSheet: Bool = false
    
    private var warehouseAddressExists: Bool {
        warehouseViewModel.warehouses.contains(where: { $0.address.id == newWarehouse.address.id })
    }
    
    var body: some View {
        VStack(spacing: 16) {
            TopBar()
            
            StorageSection()
            
            Spacer()
            
            Link("Suggest a Feature", destination: URL(string: "https://docs.google.com/document/d/19aw0hf8dCUa8ycFY7alWmv5hmq79pkwnndopVsu-IEE/edit?usp=sharing")!)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .bold()
                .foregroundColor(.red)
            
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .toolbar(.hidden)
        .task {
            if warehouseViewModel.warehouses.isEmpty {
                await warehouseViewModel.fetchWarehouses()
            }
        }
        .sheet(isPresented: $showAddressSheet) {
            AddressSheet(selectedAddress: $newWarehouse.address, addressId: $newWarehouse.id)
                .onDisappear {
                    if newWarehouse.address.isInitialized() {
                        showWarehouseNameAlert = true
                    }
                }
        }
        .alert(warehouseAddressExists ? "Warehouse with that address already exists." : "Enter Warehouse Name", isPresented: $showWarehouseNameAlert) {
            WarehouseNameAlertContent()
        }
        .alert("Confirm Delete", isPresented: $showWarehouseDeleteAlert) {
            Button("Cancel", role: .cancel) {
                showWarehouseDeleteAlert = false
            }
        } message: {
            Text("Reach out to administrator to delete this storage location permanently.")
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheet()
        }
    }
    
        // MARK: Top Bar
    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(leadingView: {
            Text("Options")
                .font(.system(.title2, design: .default))
                .foregroundColor(.red)
                .bold()
        }, header: {
            EmptyView()
        }, trailingView: {
            ProfileImage()
        })
    }
    
        // MARK: Profile Image
    @ViewBuilder
    private func ProfileImage() -> some View {
        Button {
            showProfileSheet = true
        } label: {
            Image(systemName: SFSymbols.personCircle)
                .foregroundColor(.red)
                .font(.system(size: 24))
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
                
                if showWarehouseSection {
                    RDButton(variant: editingWarehouses ? .red : .outline, size: .icon, leadingIcon: "square.and.pencil", iconBold: true, fullWidth: false) {
                        editingWarehouses.toggle()
                    }
                }
                
                RDButton(variant: .outline, size: .icon, leadingIcon: showWarehouseSection ? "chevron.up" : "chevron.down", iconBold: true, fullWidth: false) {
                    withAnimation {
                        showWarehouseSection.toggle()
                        editingWarehouses = false
                    }
                }
            }
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
            
            if showWarehouseSection {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(warehouseViewModel.warehouses, id: \.self) { warehouse in
                        WarehouseListItem(warehouse: warehouse)
                    }
                    
                    if editingWarehouses {
                        RDButton(variant: .secondary, size: .default, leadingIcon: "plus", label: "Add Warehouse", fullWidth: true) {
                            newWarehouse = WarehouseV2(displayName: "", address: Address())
                            showAddressSheet = true
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
            TextField("Warehouse Name", text: $warehouseName)
                .textInputAutocapitalization(.never)
            
            Button("OK") {
                warehouseViewModel.addWarehouse(warehouse: WarehouseV2(displayName: warehouseName, address: newWarehouse.address))
                showWarehouseNameAlert = false
                newWarehouse = WarehouseV2(displayName: warehouseName, address: newWarehouse.address)
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
            
            if editingWarehouses {
                Button {
                    showWarehouseDeleteAlert = true
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
    
        // MARK: Profile Sheet
    @ViewBuilder
    private func ProfileSheet() -> some View {
        VStack(spacing: 12) {
            Text("Profile Section")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("You currently can't sign in with an account. But this section will be available in the future 🙂")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    OptionsView()
}
