//
//  ItemDetailViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import SwiftUI

struct ItemDetailViewV2: View {
    // Environment
    @Environment(\.dismiss) private var dismiss

    // Data
    @State private var viewModel: ItemDetailViewModel

    // Presented
    @State private var showEditSheet: Bool = false
    @State private var showInformation: Bool = false

    init(item: ItemV2) {
        viewModel = ItemDetailViewModel(item: item)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar()
                    .padding(.horizontal, 16)

                ScrollView {
                    VStack(spacing: 12) {
                        ItemImageView(
                            image: viewModel.item.primaryImage,
                            selectedImage: $viewModel.selectedRDImage,
                            isImageSelected: $viewModel.isImageSelected
                        )

                        VStack(spacing: 12) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    showInformation.toggle()
                                }
                            }) {
                                HStack(spacing: 0) {
                                    Text("Information")
                                        .foregroundColor(.white)
                                        .bold()

                                    Spacer()

                                    Image(systemName: showInformation ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.white)
                                }
                                .padding(8)
                                .background(.red)
                                .cornerRadius(6)
                            }

                            if showInformation {
                                ItemDetailSection(item: viewModel.item)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .padding(.top, 4)
                    .frameHorizontalPadding()
                }
            }
            .frameTop()
            .toolbar(.hidden)
            .sheet(isPresented: $showEditSheet) {
                EditItemSheetV2(viewModel: viewModel)
            }
            .overlay(
                ModelRDImageOverlay(
                    selectedRDImage: viewModel.selectedRDImage,
                    isImageSelected: $viewModel.isImageSelected
                )
                .animation(.easeInOut(duration: 0.3), value: viewModel.isImageSelected)
            )

            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Saving Item...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
            }
        }
    }

    // MARK: - Top Bar

    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(
            leadingView: {
                BackButton()
            },
            header: {
                HStack {
                    Text("Name:")
                        .font(.headline)
                    Text(viewModel.item.name)
                }
            },
            trailingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: "square.and.pencil", iconBold: true, fullWidth: false) {
                    showEditSheet = true
                }
                .clipShape(Circle())
            }
        )
    }
}
