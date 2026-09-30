//
//  InstallPullListStoragePicker.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import SwiftUI

struct InstallPullListStoragePicker: View {
    
    let item: ItemV2
    let installStates: [String: DocumentLocation]
    let storageLocations: [StorageLocation]
    let action: (Any?) -> Void
    
    @State private var showStorageLocationSheet: Bool = false
    
    var body: some View {
        let current = installStates[item.id]?.status
        SegmentedPicker(
            segments: [
                .init("Install", selectedColor: .green) {
                    action(InstallPullListRoomAction.installItem(itemId: item.id))
                },
                .init("Store", selectedColor: .gray) {
                    showStorageLocationSheet = true
                }
            ],
            selectedIndex: current == .inInstalledList ? 0 : current == .inStorage ? 1 : nil
        )
        .sheet(isPresented: $showStorageLocationSheet) {
            SelectDocumentSheet(title: "Select Storage", documents: storageLocations) { a in
                if case .selected(let wh) = a as? SelectDocumentSheetAction<StorageLocation> {
                    action(InstallPullListRoomAction.storeItem(itemId: item.id, storageLocationId: wh.id))
                }
            }
        }
    }
}
