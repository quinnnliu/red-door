//
//  AccessoriesListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/21/26.
//

import SwiftUI

enum AccessoriesListItemAction {
    case navigate(Accessories)
}

struct AccessoriesListItemView: View {
    let accessories: Accessories
    var action: ((Any?) -> Void)?
    var actionType: AccessoriesListItemAction
    var onRemove: (() -> Void)?

    init(
        accessories: Accessories,
        action: ((Any?) -> Void)? = nil,
        actionType: AccessoriesListItemAction? = nil,
        onRemove: (() -> Void)? = nil
    ) {
        self.accessories = accessories
        self.action = action
        self.actionType = actionType ?? .navigate(accessories)
        self.onRemove = onRemove
    }

    var body: some View {
        Group {
            if let action {
                Button {
                    action(actionType)
                } label: {
                    cellContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cellContent
            }
        }
    }

    private var cellContent: some View {
        HStack(spacing: 12) {
            PrimaryImageView(image: accessories.primaryImage, size: Constants.Image.listItemDefault, isExpandable: false)

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
