//
//  UninstallAssignedItemsList.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/28/26.
//

import SwiftUI

/// The rows under a destination section. The section header names where these
/// are headed, so the rows carry no destination of their own.
struct UninstallAssignedItemsList<RowTrailing: View>: View {
    let entries: [(item: ItemV2, room: RoomV2)]
    @ViewBuilder let rowTrailing: (ItemV2) -> RowTrailing

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(entries, id: \.item.id) { entry in
                UninstallAssignedItemRow(item: entry.item, room: entry.room) {
                    rowTrailing(entry.item)
                }
            }
        }
    }
}

extension UninstallAssignedItemsList where RowTrailing == EmptyView {
    init(entries: [(item: ItemV2, room: RoomV2)]) {
        self.init(entries: entries) { _ in EmptyView() }
    }
}
