//
//  InstallPullListStoragePicker.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import SwiftUI

struct InstallPullListStoragePicker: View {
    
    let item: ItemV2
    let installStates: [String: (status: ItemStatus, locationId: String)]
    let warehouses: [WarehouseV2]
    let action: (Any?) -> Void
    
    @State private var showWarehouseSheet: Bool = false
    
    var body: some View {
        let current = installStates[item.id]?.status
        SegmentedPicker(
            segments: [
                .init("Install", selectedColor: .green) {
                    action(InstallPullListRoomAction.installItem(itemId: item.id))
                },
                .init("Store", selectedColor: .gray) {
                    showWarehouseSheet = true
                }
            ],
            selectedIndex: current == .inInstalledList ? 0 : current == .inStorage ? 1 : nil
        )
        .sheet(isPresented: $showWarehouseSheet) {
            SelectDocumentSheet<WarehouseV2>(title: "Select Warehouse", documents: warehouses) { a in
                if case .selected(let wh) = a as? SelectDocumentSheetAction<WarehouseV2> {
                    action(InstallPullListRoomAction.storeItem(itemId: item.id, warehouseId: wh.id))
                }
            }
        }
    }
}
