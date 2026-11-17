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
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(history.enumerated()), id: \.offset) { index, entry in
                    if index == 0 {
                        Text("Current")
                            .font(.title3.bold())
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Image(systemName: SFSymbols.arrowUp)
                            .foregroundStyle(.red)
                    }
                    row(entry)
                }
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .presentationDetents([.medium, .large])
    }

    private func row(_ entry: DocumentLocation) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            
            HStack(alignment: .top) {
                Text(entry.locationName ?? entry.status.rawValue)

                LocationStatusCTA(location: entry, useStatusTypeString: true)
            }
                
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.Padding(1))
        .background(Color(.systemGray5))
        .clipShape(.rect(cornerRadius: 8))
    }
}
