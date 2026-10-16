//
//  MultiFilterEnumGridPicker.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/16/26.
//

import SwiftUI

/// Multi-select counterpart of `FilterEnumGridPicker`. Stays open between taps and stops
/// accepting new selections at `maxSelections`.
///
/// The cap keeps queries inside Firestore's 30-disjunction limit: with three multi-select
/// fields, 3 x 3 x 3 = 27. Raising it above 3 on all three needs a combined-product check.
struct MultiFilterEnumGridPicker<T: Filterable>: View {
    static var maxSelections: Int { 3 }

    @Binding var selectedItems: Set<T>

    private let items: [T]
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    init(selectedItems: Binding<Set<T>>, items: [T]) {
        self._selectedItems = selectedItems
        self.items = items
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(items, id: \.self) { item in
                itemCell(item)
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(Constants.CornerRadius.medium)
    }

    // MARK: - Item Cell

    private func itemCell(_ item: T) -> some View {
        let isSelected = selectedItems.contains(item)
        let isDisabled = !isSelected && selectedItems.count >= Self.maxSelections
        return Button {
            withAnimation(Constants.Animation.snappy) {
                if isSelected {
                    selectedItems.remove(item)
                } else {
                    selectedItems.insert(item)
                }
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
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
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
