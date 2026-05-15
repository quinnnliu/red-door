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
    
    @State private var selectedType: ItemType? = nil
    private let action: (Any?) -> Void
    
    init(
        action: @escaping (Any?) -> Void
    ) {
        self.action = action
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ItemType.allCases, id: \.rawValue) { type in
                    Button(action: {
                        withAnimation(.snappy) {
                            let newType: ItemType? = selectedType == type ? nil : type
                            selectedType = newType
                            action(ItemInventoryFilterViewAction.selectItemType(newType: newType))
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

enum ItemInventoryFilterViewAction {
    case selectItemType(newType: ItemType?)
}
