//
//  UnstageItemSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/14/25.
//

import SwiftUI

struct UnstageItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stagedItems: [Item]
    @Binding var unstagedItems: [Item]

    @State private var warehouseViewModel: WarehouseViewModel = WarehouseViewModel()
    @State private var itemViewModel: ItemViewModel
    let item: Item
    let model: Model
    
    @State private var showAlert: Bool = false

    init(_ itemAndModel: (Item, Model), stagedItems: Binding<[Item]>, unstagedItems: Binding<[Item]>) {
        self.item = itemAndModel.0
        self.model = itemAndModel.1
        self.itemViewModel = ItemViewModel(selectedItem: item)
        _stagedItems = stagedItems
        _unstagedItems = unstagedItems
    }

    // MARK: Body
    var body: some View {
        VStack(spacing: 12) {
            DragIndicator()

            HStack(spacing: 0) {
                Text("Select Warehouse: ")
                    .font(.headline)
                    .foregroundColor(.red)

                Text(model.name)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            ItemModelImage(item: item, model: model, size: Constants.screenWidthPadding / 2)

            ScrollView {
                LazyVStack {
                    ForEach(warehouseViewModel.warehouses, id: \.self) { warehouse in
                        WarehouseListItem(warehouse: warehouse)
                    }
                }
            }
        }
        .task {
            await warehouseViewModel.fetchWarehouses()
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .presentationDetents([.medium])
        .toolbar(.hidden)
    }

    // MARK: Warehouse List Item

    @ViewBuilder
    private func WarehouseListItem(warehouse: Warehouse) -> some View {
        Button {
            Task {
                let result = await itemViewModel.unstageItem(warehouseId: warehouse.id)
                stagedItems.removeAll { $0.id == result.id }
                unstagedItems.append(result)
                dismiss()
            }
        } label: {
            HStack(spacing: 16) {
                Text(warehouse.name)
                    .foregroundColor(.primary)
                    .bold()
                    
                VStack(alignment: .leading, spacing: 0) {
                    Text(warehouse.address.getStreetAddress() ?? "")
                        .foregroundColor(.primary)
                        .font(.caption)

                    Text(warehouse.address.getCityStateZipcode() ?? "")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}