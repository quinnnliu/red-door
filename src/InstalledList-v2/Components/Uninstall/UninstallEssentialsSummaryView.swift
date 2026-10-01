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
        ExpandableSectionView(
            style: .uninstallEssentials(
                group: group,
                accessories: accessories,
                itemCount: items.count,
                destinationLabel: destinationLabel,
                destinationSubtitle: destinationSubtitle
            ),
            trailing: trailing
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Moves as a unit")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(items, id: \.id) { item in
                    ItemListItemView(item: item, style: .display)
                }
            }
        }
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
