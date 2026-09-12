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
    @State private var showInformation: Bool = true
    @State private var showQRCodeLabel: Bool = false

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

                        ItemDetails
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
            .fullScreenCover(isPresented: $showQRCodeLabel) {
                ItemV2LabelView(item: viewModel.item)
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
                VStack(alignment: .center, spacing: 6) {
                    HStack {
                        Text("Name:")
                            .font(.headline)
                        Text(viewModel.item.displayName)
                    }
                    if let nickname = viewModel.item.nickname {
                        Text("Nickname: \(nickname)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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

extension ItemDetailViewV2 {
    var ItemDetails: some View {
        VStack(spacing: 12) {
            
            HStack {
                SmallCTA(type: .secondary, leadingIcon: SFSymbols.qrcode, text: "Label") {
                    showQRCodeLabel = true
                }
                
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showInformation.toggle()
                    }
                } label: {
                    
                    HStack(spacing: 8) {
                        Image(systemName: SFSymbols.infoCircleFill)
                            .foregroundColor(.white)
                        Text("Information")
                            .foregroundColor(.white)
                        Image(systemName: SFSymbols.chevronDown)
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(showInformation ? 0 : -90))
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showInformation)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.red)
                    .cornerRadius(12)
                }
            }

            if showInformation {
                ItemDetailSection(item: viewModel.item)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top)),
                        removal:   .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                    ))
            }
        }
    }
}
