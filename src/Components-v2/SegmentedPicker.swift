//
//  SegmentedPicker.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import SwiftUI

struct SegmentedPicker: View {
    let segments: [(label: String, action: () -> Void)]
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
                        .background(isSelected ? Color.red : Color(.systemGray4))
                }
                .buttonStyle(.plain)
                
                if index < segments.count - 1 {
                    Divider()
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(.separator), lineWidth: 1))
    }
}
