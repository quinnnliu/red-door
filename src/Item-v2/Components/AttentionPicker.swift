//
//  AttentionPicker.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/01/26.
//

import SwiftUI

struct AttentionPicker: View {
    @Binding var needsAttention: Bool
    @Binding var attentionDescription: String?

    @State private var showSheet: Bool = false

    // MARK: Body

    var body: some View {
        HStack(spacing: .zero) {
            Text("Attention:")
                .foregroundColor(.red)
                .bold()

            Spacer(minLength: .zero)

            Button {
                showSheet = true
            } label: {
                HStack(spacing: Constants.Padding(0.5)) {
                    if needsAttention {
                        Image(systemName: SFSymbols.exclamationmarkTriangleFill)
                            .foregroundStyle(.orange)
                    }
                    Text(needsAttention ? "Needs Attention" : "None")
                        .foregroundStyle(needsAttention ? Color.orange : Color.blue)
                }
                .font(.caption2)
                .padding(8)
                .background(Color(.systemGray4))
                .cornerRadius(Constants.CornerRadius.small)
            }
        }
        .sheet(isPresented: $showSheet) {
            AttentionSheet(
                needsAttention: $needsAttention,
                attentionDescription: $attentionDescription
            )
            .presentationDetents([.fraction(0.25), .medium])
        }
    }
}

// MARK: - AttentionSheet

private struct AttentionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var needsAttention: Bool
    @Binding var attentionDescription: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Attention")
                .font(.headline)
                .foregroundStyle(.red)
                .bold()

            Toggle("Needs Attention", isOn: $needsAttention.animation(Constants.Animation.snappy))
                .tint(.red)

            if needsAttention {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description (optional):")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("What's wrong with this item?", text: descriptionBinding, axis: .vertical)
                        .lineLimit(2...5)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(Constants.CornerRadius.medium)
                }
            }

            Spacer()

            RDButton(variant: .red, size: .default, label: "Done") {
                dismiss()
            }
        }
        .padding()
        .onChange(of: needsAttention) { _, newValue in
            if !newValue { attentionDescription = nil }
        }
    }

    private var descriptionBinding: Binding<String> {
        Binding(
            get: { attentionDescription ?? "" },
            set: { attentionDescription = $0.isEmpty ? nil : $0 }
        )
    }
}
