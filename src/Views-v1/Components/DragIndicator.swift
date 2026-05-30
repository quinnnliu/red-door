//
//  SheetDragBar.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/6/25.
//

import SwiftUI

struct DragIndicator: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.secondary.opacity(0.5))
            .frame(width: 36, height: 5)
            .padding(.vertical, 8)
    }
}