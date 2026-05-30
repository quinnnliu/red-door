//
//  GridPicker.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/21/24.
//

import SwiftUI

// MARK: - GridPicker

struct GridPicker: View {
    @Binding var selectedItem: String
    @Binding var isActive: Bool
    var title: String
    var items: [String] 

    init(selectedItem: Binding<String>, isActive: Binding<Bool>, title: String, items: [String]) {
        _selectedItem = selectedItem
        _isActive = isActive
        self.title = title
        self.items = items
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Display ungrouped items (like materials)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 6) {
                ForEach(items, id: \.self) { item in
                    GridOptionView(
                        itemName: item,
                        color: Model.colorMap[item],
                        isSelected: selectedItem == item
                    ) {
                        selectedItem = item
                        withAnimation(.spring(response: 0.3)) {
                            isActive = false
                        }
                    }
                }
            }
        }
        .padding(8)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray5), lineWidth: 2)
        )
    }
}

// MARK: - GridOptionView

struct GridOptionView: View {
    let itemName: String
    let color: Color?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                if let color = color {
                    // Display color circle if color is provided
                    Image(systemName: SFSymbols.circleFill)
                        .font(.system(size: 16))
                        .foregroundStyle(color)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                .padding(2)
                        )
                }
                
                Text(itemName)
                    .font(.system(size: 10))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

