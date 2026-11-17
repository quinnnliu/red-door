//
//  ItemLocationHistorySheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 11/11/26.
//

import SwiftUI

struct ItemLocationHistorySheet: View {
    let history: [DocumentLocation]

    var body: some View {
        VStack(spacing: 4) {
            DragIndicator()
            
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(Array(history.enumerated()), id: \.offset) { index, entry in
                        if index == 0 {
                            Text("Current")
                                .font(.title3.bold())
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Image(systemName: SFSymbols.arrowUp)
                                .foregroundStyle(.red)
                        }
                        row(entry, isCurrent: index == 0)
                    }
                }
                .padding()

            }
            .presentationDetents([.medium, .large])
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
        .padding(Constants.Padding(1))
        .background(isCurrent ? Color.red.opacity(0.25) : Color(.systemGray5))
        .clipShape(.rect(cornerRadius: 8))
    }
}
