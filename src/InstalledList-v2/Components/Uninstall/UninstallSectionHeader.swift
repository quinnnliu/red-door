//
//  UninstallSectionHeader.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/28/26.
//

import SwiftUI

struct UninstallSectionHeader: View {
    let title: String
    var count: Int? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.red)

            Spacer()

            if let count {
                Text("(\(count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .background(Color(.systemBackground))
    }
}
