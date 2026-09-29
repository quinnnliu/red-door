//
//  UninstallAssignedItemRow.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/28/26.
//

import SwiftUI

/// An item shown with the room it was installed in. The trailing slot is left to
/// the calling screen, which is the only one that knows whether the row is still
/// editable.
struct UninstallAssignedItemRow<Trailing: View>: View {
    let item: ItemV2
    let room: RoomV2
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 8) {
            ItemListItemView(item: item, style: .installation(room: room))

            trailing()
        }
    }
}

extension UninstallAssignedItemRow where Trailing == EmptyView {
    init(item: ItemV2, room: RoomV2) {
        self.init(item: item, room: room) { EmptyView() }
    }
}
