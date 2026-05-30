//
//  ModelInventoryFilterView.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/5/25.
//

import Foundation
import SwiftUI

struct ModelInventoryFilterView: View {
    @Environment(\.colorScheme) private var scheme
    @Binding var selectedType: ModelType?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ModelType.allCases, id: \.rawValue) { type in
                    Button(action: {
                        withAnimation(.snappy) {
                            if selectedType == type {
                                selectedType = nil
                            } else {
                                selectedType = type
                            }
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

    private func foregroundColor(for type: ModelType) -> Color {
        selectedType == type ? /* (scheme == .dark ? Color.black : Color.white) */ Color.white : Color.primary
    }

    private func backgroundView(for type: ModelType) -> some View {
        Capsule()
            .fill(selectedType == type ? Color.accentColor : Color(.systemGray5))
    }
}
