//
//  RoomItemPreview.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/01/26.
//

import SwiftUI

enum RoomItemPreviewAction {
    case navigate(item: ItemV2)
}

struct RoomItemPreview: View {
    private let item: ItemV2
    private let action: ((Any) -> Void)?

    init(_ item: ItemV2, action: ((Any) -> Void)? = nil) {
        self.item = item
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button {
            action?(RoomItemPreviewAction.navigate(item: item))
        } label: {
            HStack(alignment: .center, spacing: 12) {
                PrimaryImageView(image: item.primaryImage, size: Constants.Image.listItemDefault, isExpandable: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: 4) {
                        Image(systemName: item.type.icon ?? SFSymbols.ellipsis)
                            .foregroundColor(.secondary)

                        if let color = item.color.color {
                            Image(systemName: SFSymbols.circleFill)
                                .foregroundColor(color)
                        }
                        
                        Text(item.material.title)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 0)
                
                if item.attention {
                    Image(systemName: SFSymbols.exclamationmarkTriangleFill)
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption2)
            .frame(maxWidth: .infinity)
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
    }

    private var borderColor: Color {
        item.attention ? .orange : Color(.systemGray3)
    }
}
