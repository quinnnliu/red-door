//
//  AccessoriesListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

import SwiftUI

struct AccessoriesListItemView: View {
    let accessories: Accessories

    var body: some View {
        HStack(spacing: 12) {
            ItemListItemImage(accessories.primaryImage)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(accessories.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if accessories.status != .inStorage {
                        Text("• \(accessories.status.displayTitle)")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer()
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}
