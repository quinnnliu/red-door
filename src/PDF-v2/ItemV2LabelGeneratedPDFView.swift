//
//  ItemV2LabelGeneratedPDFView.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/22/25.
//

import SwiftUI

/// The location fields a label prints, resolved from the item's `locationId`.
struct ItemLocationInfo {
    let name: String
    let address: String
}

struct ItemV2LabelGeneratedPDFView: View {
    // MARK: Init Values

    let item: ItemV2
    let location: ItemLocationInfo?
    let qrCodeImage: UIImage?
    let itemImage: UIImage?

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Name: \(item.displayName)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.red)

            HStack(spacing: 20) {
                if let qrCodeImage = qrCodeImage {
                    Image(uiImage: qrCodeImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                } else {
                    Text("Error Generating QR Code")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .frame(width: 200, height: 200)
                }

                // Item Image
                if let itemImage = itemImage {
                    Image(uiImage: itemImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipped()
                } else {
                    Rectangle()
                        .foregroundColor(Color(.systemGray5))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: SFSymbols.photoBadgePlus)
                                .font(.system(size: 40))
                                .bold()
                                .foregroundColor(.secondary)
                        )
                }
            }

            LocationAndDescription

            Divider()

            Details
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(40)
        .background(Color.white)
    }
}

// MARK: - Location and Description

private extension ItemV2LabelGeneratedPDFView {

    /// Location sits under the QR code at its width; description takes the rest.
    var LocationAndDescription: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Location:")
                    .font(.system(size: 14, weight: .bold))

                if let location {
                    Text(location.name)
                        .font(.system(size: 12))

                    Text(location.address)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                } else {
                    Text("No location")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 200, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("Description:")
                    .font(.system(size: 14, weight: .bold))

                Text(item.description)
                    .font(.system(size: 12))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray5))
                    .cornerRadius(Constants.CornerRadius.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Details

private extension ItemV2LabelGeneratedPDFView {

    /// Glanceable facts in small type, wrapping onto a second line only when
    /// they don't fit. Optional fields are left out when missing.
    var Details: some View {
        WrappingRow(spacing: 14, lineSpacing: 3) {
            if let value = item.value {
                Detail("Value", String(format: "$%.2f", value))
            }
            if let brand = item.brand {
                Detail("Brand", brand)
            }
            if let purchaseLocation = item.purchaseLocation {
                Detail("Purchased at", purchaseLocation)
            }
            if let datePurchased = item.datePurchased {
                Detail("Purchased", datePurchased)
            }
            Detail("Type", item.type.title)
            Detail("Color", item.color.title)
            Detail("Material", item.material.title)
            if let dimensions = item.dimensions?.summary {
                Detail("Dimensions", dimensions)
            }
        }
    }

    func Detail(_ label: String, _ value: String) -> some View {
        Text("\(Text("\(label): ").foregroundColor(.secondary))\(value)")
            .font(.system(size: 9))
    }
}

// MARK: - WrappingRow

/// Lays children out left to right and starts a new line when one wouldn't fit.
/// A custom `Layout` rather than a lazy grid, so `ImageRenderer` measures and
/// draws every child.
private struct WrappingRow: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var usedWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                totalHeight += lineHeight + lineSpacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            usedWidth = max(usedWidth, x - spacing)
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: proposal.width ?? usedWidth, height: totalHeight + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += lineHeight + lineSpacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
