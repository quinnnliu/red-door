//
//  UninstallDestinationGroupsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/28/26.
//

import SwiftUI

typealias UninstallDestinationGroup = (label: String, items: [(item: ItemV2, room: RoomV2)])

/// Items grouped by where they are headed rather than by room of origin — once
/// something has a destination, that is the only question left about it.
struct UninstallDestinationGroupsView<RowTrailing: View>: View {
    let groups: [UninstallDestinationGroup]
    @ViewBuilder let rowTrailing: (ItemV2) -> RowTrailing

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(groups, id: \.label) { group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(group.label)
                            .font(.subheadline)
                            .bold()

                        Spacer()

                        Text("(\(group.items.count))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(group.items, id: \.item.id) { entry in
                        UninstallAssignedItemRow(item: entry.item, room: entry.room) {
                            rowTrailing(entry.item)
                        }
                    }
                }
            }
        }
    }
}

extension UninstallDestinationGroupsView where RowTrailing == EmptyView {
    init(groups: [UninstallDestinationGroup]) {
        self.init(groups: groups) { _ in EmptyView() }
    }
}
