//
//  InstallItemListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/25/26.
//

import SwiftUI

struct InstallItemListItemView: View {
    let item: ItemV2
    let installStates: [String: DocumentLocation]
    let warehouses: [WarehouseV2]
    let action: (Any?) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ItemListItemView(item: item, style: .display)

            VStack(alignment: .center, spacing: 4) {
                InstallPullListStoragePicker(
                    item: item,
                    installStates: installStates,
                    warehouses: warehouses,
                    action: action
                )

                if let label = storageLabel {
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(8)
        }
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }

    private var storageLabel: String? {
        guard let state = installStates[item.id], state.status == .inStorage else { return nil }
        return warehouses.first(where: { $0.id == state.locationId })?.displayName
    }
}
