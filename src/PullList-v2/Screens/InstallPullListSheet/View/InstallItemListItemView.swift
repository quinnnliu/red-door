//
//  InstallItemListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/25/26.
//

import SwiftUI

struct InstallItemListItemView: View {
    let item: ItemV2
    let room: RoomV2
    let installStates: [String: DocumentLocation]
    let storageLocations: [StorageLocation]
    let action: (Any?) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ItemListItemView(item: item, style: .installation(room: room))
                .frame(maxWidth: .infinity)

            VStack(alignment: .center, spacing: 4) {
                InstallPullListStoragePicker(
                    item: item,
                    installStates: installStates,
                    storageLocations: storageLocations,
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
        .cornerRadius(Constants.CornerRadius.large)
    }

    private var storageLabel: String? {
        guard let state = installStates[item.id], state.status == .inStorage else { return nil }
        return storageLocations.first(where: { $0.id == state.locationId })?.displayName
    }
}
