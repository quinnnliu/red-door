//
//  CreateAccessoriesView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import SwiftUI

struct CreateAccessoriesView: View {
    @State private var viewModel: CreateAccessoriesViewModel = CreateAccessoriesViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar

                ScrollView {
                    // TODO: type picker (existing types + create new)
                    // TODO: image picker
                    // TODO: description field

                    RDButton(
                        variant: .default,
                        size: .default,
                        leadingIcon: "plus",
                        label: "Add Accessory"
                    ) {
                        Task {
                            await viewModel.createAccessories()
                            dismiss()
                        }
                    }
                }
                .ignoresSafeArea(.keyboard)
            }
            .toolbar(.hidden)
            .frameTop()
            .frameHorizontalPadding()

            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Saving...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
            }
        }
        .task {
            await viewModel.loadTypes()
        }
    }

    // MARK: - TopBar

    @ViewBuilder
    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: "xmark", iconBold: true, fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                TextField("Accessory Name", text: $viewModel.displayName)
                    .padding(6)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    .multilineTextAlignment(.center)
            },
            trailingView: {
                Spacer().frame(24)
            }
        )
    }
}

#Preview {
    CreateAccessoriesView()
}
