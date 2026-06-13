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
    let action: (Any?) -> Void

    var body: some View {
        VStack(spacing: 20) {
            DragIndicator()

            Text("Install \(summary.address)?")
                .font(.title3)
                .bold()

            Group {
                VStack(alignment: .leading, spacing: 12) {
                    (
                        Text("\(summary.installedCount) \(summary.installedCount == 1 ? "item" : "items") ")
                            .bold()
                            .foregroundStyle(.red)
                        +
                        Text("will be installed")
                    ).font(.headline)
                }
                
                if !summary.storageBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(summary.storageBreakdown.map(\.count).reduce(0, +)) \(summary.storageBreakdown.map(\.count).reduce(0, +) == 1 ? "item" : "items") go to storage:")
                            .font(.headline)
                        
                        ForEach(summary.storageBreakdown, id: \.warehouseName) { entry in
                            HStack(spacing: 8) {
                                Image(systemName: "shippingbox")
                                    .foregroundStyle(.secondary)
                                Text("\(entry.warehouseName) — \(entry.count) \(entry.count == 1 ? "item" : "items")")
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Spacer()

            // MARK: Actions
            HStack(spacing: 12) {
                RDButton(variant: .outline, size: .default, label: "Cancel", fullWidth: true) {
                    dismiss()
                }

                RDButton(variant: .red, size: .default, label: "Confirm", fullWidth: true) {
                    action(ConfirmInstallSheetAction.confirm)
                    dismiss()
                }
            }
        }
        .frameTop()
        .frameVerticalPadding()
        .frameHorizontalPadding()
        .presentationDetents([.medium])
    }
}

enum ConfirmInstallSheetAction {
    case confirm
}
