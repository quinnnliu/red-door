//
//  ItemLocationHistorySheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 11/11/26.
//

import SwiftUI

/// Minimal placeholder layout: newest first, current location highlighted,
/// arrows pointing from each previous location up to the one that followed it.
/// Restyle freely; `history` is expected newest first (`ItemV2.sortedLocationHistory`).
struct ItemLocationHistorySheet: View {
    let history: [DocumentLocation]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(history.enumerated()), id: \.offset) { index, entry in
                    if index > 0 {
                        Image(systemName: SFSymbols.arrowUp)
                    }
                    row(entry, isCurrent: index == 0)
                }
            }
            .padding()
        }
    }

    private func row(_ entry: DocumentLocation, isCurrent: Bool) -> some View {
        VStack(spacing: 2) {
            Text(entry.locationName ?? entry.status.rawValue)
                .bold(isCurrent)
            if let assignedAt = entry.assignedAt {
                Text(assignedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Date unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(isCurrent ? Color.red.opacity(0.15) : Color.clear)
        .clipShape(.rect(cornerRadius: 8))
    }
}
