//
//  EnumGridPicker.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/11/26.
//
import SwiftUI

struct EnumGridPicker<T: Hashable>: View {
    @Binding var selectedItem: T
    @Binding var isActive: Bool
    let items: [T]
    let label: (T) -> String
    let color: (T) -> Color?
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 5)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(items, id: \.self) { item in
                Button {
                    selectedItem = item
                    withAnimation(.spring(response: 0.3)) {
                        isActive = false
                    }
                } label: {
                    VStack(spacing: 2) {
                        if let itemColor = color(item) {
                            Image(systemName: SFSymbols.circleFill)
                                .font(.system(size: 16))
                                .foregroundStyle(itemColor)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        .padding(2)
                                )
                        }
                        
                        Text(label(item))
                            .font(.system(size: 10))
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedItem == item ? Color.blue.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        ))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray5), lineWidth: 2)
        )
        .onTapGesture { isActive = false }
    }
}
