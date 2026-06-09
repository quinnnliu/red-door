//
//  ConfirmInstallSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/8/26.
//

import SwiftUI

struct ConfirmInstallSheet: View {
    @Environment(\.dismiss) private var dismiss

    let summary: ConfirmInstallSummary
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            DragIndicator()

            // MARK: Header
            Text("Install this list?")
                .font(.title3)
                .bold()

            // MARK: Summary
            VStack(alignment: .leading, spacing: 12) {
                Text("\(summary.installedCount) \(summary.installedCount == 1 ? "item" : "items") will be installed at \(summary.address)")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !summary.storageBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(summary.storageBreakdown.map(\.count).reduce(0, +)) \(summary.storageBreakdown.map(\.count).reduce(0, +) == 1 ? "item" : "items") go to storage:")
                            .font(.subheadline)

                        ForEach(summary.storageBreakdown, id: \.warehouseName) { entry in
                            HStack(spacing: 8) {
                                Image(systemName: "shippingbox")
                                    .foregroundStyle(.secondary)
                                Text("\(entry.warehouseName) — \(entry.count) \(entry.count == 1 ? "item" : "items")")
                                    .font(.subheadline)
                                    .bold()
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)

            Spacer()

            // MARK: Actions
            HStack(spacing: 12) {
                RDButton(variant: .outline, size: .default, label: "Cancel", fullWidth: true) {
                    onCancel()
                    dismiss()
                }

                RDButton(variant: .red, size: .default, label: "Confirm", fullWidth: true) {
                    onConfirm()
                    dismiss()
                }
            }
        }
        .frameTop()
        .frameHorizontalPadding()
        .presentationDetents([.medium])
    }
}
