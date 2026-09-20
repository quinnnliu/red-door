//
//  AccessoriesListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

import SwiftUI

struct AccessoriesListItemView: View {
    let accessories: Accessories
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailImageView(accessories.primaryImage)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(accessories.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if accessories.location.status != .inStorage {
                        Text("• \(accessories.location.status.displayTitle)")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer()

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: SFSymbols.xmark)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}
