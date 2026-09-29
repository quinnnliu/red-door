//
//  UninstallEssentialsSummaryView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/28/26.
//

import SwiftUI

struct UninstallEssentialsSummaryView<Trailing: View>: View {
    let group: EssentialsGroup
    let items: [ItemV2]
    let accessories: Accessories?
    let destinationLabel: String?
    var destinationSubtitle: String? = nil
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(group.emoji)

                Text(group.displayName)
                    .font(.headline)

                Spacer(minLength: 0)

                if let destinationLabel {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(destinationLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)

                        if let destinationSubtitle {
                            Text(destinationSubtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                trailing()
            }

            Text("Moves as a unit")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(items, id: \.id) { item in
                ItemListItemView(item: item, style: .display)
            }

            if let accessories {
                HStack(spacing: 8) {
                    Image(systemName: SFSymbols.wrenchFill)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(accessories.displayName)
                        .font(.subheadline)

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(4)
        .toolbar(.hidden)
    }
}

extension UninstallEssentialsSummaryView where Trailing == EmptyView {
    init(
        group: EssentialsGroup,
        items: [ItemV2],
        accessories: Accessories?,
        destinationLabel: String?,
        destinationSubtitle: String? = nil
    ) {
        self.init(
            group: group,
            items: items,
            accessories: accessories,
            destinationLabel: destinationLabel,
            destinationSubtitle: destinationSubtitle
        ) { EmptyView() }
    }
}
