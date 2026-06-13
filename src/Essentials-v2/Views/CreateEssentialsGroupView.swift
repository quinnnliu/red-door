//
//  CreateEssentialsGroupView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import SwiftUI

struct CreateEssentialsGroupView: View {
    @State private var viewModel: CreateEssentialsGroupViewModel = CreateEssentialsGroupViewModel()
    @Environment(\.dismiss) var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar()

                ScrollView {
                    // TODO: type picker (existing types + create new)
                    // TODO: item picker (add items to group)

                    RDButton(
                        variant: .default,
                        size: .default,
                        leadingIcon: "plus",
                        label: "Create Essentials Group"
                    ) {
                        Task {
                            await viewModel.createEssentialsGroup()
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
            await viewModel.loadGroupTypes()
        }
    }

    // MARK: - Top Bar

    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(
            leadingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: "xmark", iconBold: true, fullWidth: false) {
                    dismiss()
                }
                .clipShape(Circle())
            },
            header: {
                Text(viewModel.selectedGroupType?.displayName ?? "New Essentials Group")
                    .font(.headline)
            },
            trailingView: {
                Spacer().frame(24)
            }
        )
    }
}

#Preview {
    CreateEssentialsGroupView()
}
