//
//  EssentialsGroupPicker.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/30/26.
//

import SwiftUI

struct EssentialsGroupPicker: View {
    let groups: [EssentialsGroup]
    @Binding var selected: EssentialsGroup?

    @State private var showPicker: Bool = false

    // MARK: Body

    var body: some View {
        HStack(spacing: .zero) {
            Text("Essential Group:")
                .foregroundColor(.red)
                .bold()

            Spacer(minLength: .zero)

            Button {
                showPicker = true
            } label: {
                HStack(spacing: Constants.Padding(0.5)) {
                    Text(selected.map { "\($0.emoji) \($0.displayName)" } ?? "None")

                    if selected != nil {
                        Button {
                            selected = nil
                        } label: {
                            Image(systemName: SFSymbols.xmarkCircleFill)
                                .foregroundStyle(.gray)
                                .font(.caption2)
                        }
                    }
                }
                .font(.caption2)
                .padding(8)
                .background(Color(.systemGray4))
                .cornerRadius(Constants.CornerRadius.small)
            }
        }
        .sheet(isPresented: $showPicker) {
            SelectDocumentSheet(title: "Select Essentials Group", documents: groups) { action in
                guard let action = action as? SelectDocumentSheetAction<EssentialsGroup>,
                      case .selected(let group) = action else { return }
                selected = group
            }
        }
    }
}
