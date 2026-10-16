//
//  MultiFilterPickerRow.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/16/26.
//

import SwiftUI

/// Multi-select counterpart of `FilterPickerRow`. Shows "Any", the single selected item,
/// or "N selected" when more than one is chosen; expand the row to see which.
struct MultiFilterPickerRow<T: Filterable>: View {

    @State private var isActive: Bool = false
    @Binding var selectedItems: Set<T>

    private var items: [T]
    private var title: String

    init(selectedItems: Binding<Set<T>>, items: [T], title: String) {
        self._selectedItems = selectedItems
        self.items = items
        self.title = title
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(Constants.Animation.snappy) {
                    isActive.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Spacer()

                    if selectedItems.count == 1, let item = selectedItems.first {
                        ItemIcon(item)
                    }

                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(selectedItems.isEmpty ? .secondary : Color(.red))

                    Image(systemName: isActive ? SFSymbols.chevronUp : SFSymbols.chevronDown)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isActive {
                MultiFilterEnumGridPicker(selectedItems: $selectedItems, items: items)
                    .padding(.bottom, 8)
                    .animation(Constants.Animation.snappy, value: isActive)
            }
        }
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var summary: String {
        MultiFilterPickerRow.summary(for: selectedItems)
    }

    /// Shared with locked rows so both read the same way.
    static func summary(for items: Set<T>) -> String {
        switch items.count {
        case 0:  "Any"
        case 1:  items.first!.title
        default: "\(items.count) selected"
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
