//
//  ConfirmUninstallSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/27/26.
//

import SwiftUI

enum ConfirmUninstallSheetAction {
    case confirm
}

struct ConfirmUninstallSheet: View {
    @Environment(\.dismiss) private var dismiss

    let summary: ConfirmUninstallSummary
    let action: (Any?) -> Void

    var body: some View {
        VStack(spacing: 20) {
            DragIndicator()

            Text("Uninstall \(summary.address)?")
                .font(.title3)
                .bold()

            Breakdown

            Spacer()

            Actions
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .presentationDetents([.medium])
    }
}

private extension ConfirmUninstallSheet {

    // MARK: Breakdown

    var Breakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            (
                Text("\(summary.totalCount) \(summary.totalCount == 1 ? "item" : "items") ")
                    .bold()
                    .foregroundStyle(.red)
                +
                Text("will move")
            )
            .font(.headline)

            ForEach(summary.groups, id: \.label) { group in
                HStack(spacing: 8) {
                    Image(systemName: SFSymbols.shippingbox)
                        .foregroundStyle(.secondary)

                    Text("\(group.label) — \(group.count) \(group.count == 1 ? "item" : "items")")
                        .font(.subheadline)
                }
            }

            Text("This list stays as a record of what was installed where.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Actions

    var Actions: some View {
        HStack(spacing: 12) {
            RDButton(variant: .outline, label: "Cancel", fullWidth: true) {
                dismiss()
            }

            RDButton(variant: .red, label: "Confirm", fullWidth: true) {
                action(ConfirmUninstallSheetAction.confirm)
                dismiss()
            }
        }
    }
}
