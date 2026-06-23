//
//  FilterEnumGridPicker.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/22/26.
//

import SwiftUI

struct FilterEnumGridPicker<T: Filterable>: View {
    @Binding var selectedItem: T?
    @Binding var isActive: Bool

    private var items: [T]

    init(selectedItem: Binding<T?>, isActive: Binding<Bool>, items: [T]) {
        self._selectedItem = selectedItem
        self._isActive = isActive
        self.items = items
    }

    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(items, id: \.self) { item in
                itemCell(item)
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
        .onTapGesture { isActive = false }
    }

    // MARK: - Item Cell

    private func itemCell(_ item: T) -> some View {
        let isSelected = selectedItem == item
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedItem = isSelected ? nil : item
                isActive = false
            }
        } label: {
            VStack(spacing: 2) {
                itemIcon(item, isSelected: isSelected)
                Text(item.title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? Color.red : Color.primary)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.red.opacity(0.1) : Color(.systemGray4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.red.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func itemIcon(_ item: T, isSelected: Bool) -> some View {
        if let itemColor = item.color {
            Image(systemName: "circle.fill")
                .frame(20)
                .foregroundStyle(itemColor)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        .padding(2)
                )
        } else if let itemIcon = item.icon {
            Image(systemName: itemIcon)
                .frame(20)
                .foregroundStyle(isSelected ? Color.red : Color.primary)
        }
    }
}
