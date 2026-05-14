//
//  ItemInventoryFilterView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/12/26.
//

import Foundation
import SwiftUI

struct ItemInventoryFilterView: View {
    @Environment(\.colorScheme) private var scheme
    let selectedType: ItemType?
    let onSelect: (ItemType?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ItemType.allCases, id: \.rawValue) { type in
                    Button(action: {
                        withAnimation(.snappy) {
                            onSelect(selectedType == type ? nil : type)
                        }
                    }) {
                        Text(type.rawValue)
                            .font(.callout)
                            .foregroundColor(foregroundColor(for: type))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(backgroundView(for: type))
                    }
                }
            }
        }
    }

    private func foregroundColor(for type: ItemType) -> Color {
        selectedType == type ? Color.white : Color.primary
    }

    private func backgroundView(for type: ItemType) -> some View {
        Capsule()
            .fill(selectedType == type ? Color.accentColor : Color(.systemGray5))
    }
}
