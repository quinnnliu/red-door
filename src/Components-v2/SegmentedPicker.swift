//
//  SegmentedPicker.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import SwiftUI

struct SegmentedPickerSegment {
    let label: String
    let selectedColor: Color
    let action: () -> Void
    
    init(_ label: String, selectedColor: Color = .red, action: @escaping () -> Void) {
        self.label = label
        self.selectedColor = selectedColor
        self.action = action
    }
}

struct SegmentedPicker: View {
    let segments: [SegmentedPickerSegment]
    let selectedIndex: Int?
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(segments.indices, id: \.self) { index in
                let isSelected = selectedIndex == index
                Button {
                    if !isSelected {
                        segments[index].action()
                    }
                } label: {
                    Text(segments[index].label)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white : Color.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(isSelected ? segments[index].selectedColor : Color(.systemGray4))
                }
                .buttonStyle(.plain)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                
                if index < segments.count - 1 {
                    Divider()
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
