//
//  FilterPickerRow.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/22/26.
//

import SwiftUI

struct FilterPickerRow<T: Filterable>: View {

    @State private var isActive: Bool = false
    @Binding var selectedItem: T?

    private var items: [T]
    private var title: String

    init(selectedItem: Binding<T?>, items: [T], title: String) {
        self._selectedItem = selectedItem
        self.items = items
        self.title = title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isActive.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                        
                    if let item = selectedItem {
                        ItemIcon(item)
                    }
                    
                    Text(selectedItem?.title ?? "Any")
                        .font(.subheadline)
                        .foregroundStyle(selectedItem != nil ? .red : .secondary)
                    
                    Image(systemName: isActive ? SFSymbols.chevronUp : SFSymbols.chevronDown)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isActive {
                FilterEnumGridPicker(selectedItem: $selectedItem, isActive: $isActive, items: items)
                    .padding(.bottom, 8)
                    .animation(.bouncy, value: isActive)
            }
        }
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
    
    @ViewBuilder
    private func ItemIcon(_ item: T) -> some View {
        Group {
            if let itemColor = item.color {
                Image(systemName: SFSymbols.circleFill)
                    .foregroundStyle(itemColor)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            .padding(2)
                    )
            } else if let itemIcon = item.icon {
                Image(systemName: itemIcon)
                    .foregroundStyle(Color.red)
            }
        }
        .frame(12)
    }
}
