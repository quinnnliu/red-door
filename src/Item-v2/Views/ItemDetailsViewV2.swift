//
//  ItemDetailsViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import SwiftUI

struct ItemDetailsViewV2: View {
    // Environment
    @Environment(\.dismiss) private var dismiss

    // Data
    @State private var viewModel: ItemDetailsViewModel

    // Presented
    @State private var showEditSheet: Bool = false
    @State private var showInformation: Bool = false

    init(item: ItemV2) {
        viewModel = ItemDetailsViewModel(item: item)
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
                                ItemInformationView(item: viewModel.item)
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
                EditItemInformationSheet(viewModel: viewModel)
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
            leadingIcon: {
                BackButton()
            },
            header: {
                HStack {
                    Text("Name:")
                        .font(.headline)
                    Text(viewModel.item.name)
                }
            },
            trailingIcon: {
                RDButton(variant: .red, size: .icon, leadingIcon: "square.and.pencil", iconBold: true, fullWidth: false) {
                    showEditSheet = true
                }
                .clipShape(Circle())
            }
        )
    }
}

// MARK: - Item Information View

private struct ItemInformationView: View {
    let item: ItemV2

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: Description
            VStack(alignment: .leading, spacing: 4) {
                SectionLabel("Description:")
                Text(item.description.isEmpty ? "No description" : item.description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(item.description.isEmpty ? .secondary : .primary)
                    .padding(8)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
            }

            // MARK: Type, Color, Material
            VStack(alignment: .leading, spacing: 4) {
                SectionLabel("Details:")

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Type:")
                            .frame(width: 90, alignment: .leading)
                        Text(item.type.title)
                            .padding(6)
                            .background(Color(.systemGray4))
                            .cornerRadius(6)
                    }

                    HStack {
                        Text("Color:")
                            .frame(width: 90, alignment: .leading)
                        HStack(spacing: 6) {
                            Image(systemName: SFSymbols.circleFill)
                                .foregroundStyle(item.color.color)
                            Text(item.color.title)
                        }
                        .padding(6)
                        .background(Color(.systemGray4))
                        .cornerRadius(6)
                    }

                    HStack {
                        Text("Material:")
                            .frame(width: 90, alignment: .leading)
                        Text(item.material.title)
                            .padding(6)
                            .background(Color(.systemGray4))
                            .cornerRadius(6)
                    }

                    HStack {
                        Text("Essential:")
                            .frame(width: 90, alignment: .leading)
                        Image(systemName: item.isEssential ? SFSymbols.starCircleFill : SFSymbols.circle)
                            .foregroundColor(item.isEssential ? .yellow : .gray)

                        Spacer()

                        Text("Available:")
                        Image(systemName: item.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(item.isAvailable ? .green : .red)
                    }
                }
                .padding(8)
                .background(Color(.systemGray4))
                .cornerRadius(8)
            }

            // MARK: Purchase Info (only shown if any field is set)
            if item.value != nil || item.brand != nil || item.purchaseLocation != nil || item.datePurchased != nil {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel("Purchase Info:")

                    VStack(alignment: .leading, spacing: 8) {
                        if let value = item.value {
                            HStack {
                                Text("Value ($):")
                                    .frame(width: 120, alignment: .leading)
                                Text(String(format: "%.2f", value))
                                    .padding(6)
                                    .background(Color(.systemGray4))
                                    .cornerRadius(6)
                            }
                        }
                        if let brand = item.brand {
                            HStack {
                                Text("Brand:")
                                    .frame(width: 120, alignment: .leading)
                                Text(brand)
                                    .padding(6)
                                    .background(Color(.systemGray4))
                                    .cornerRadius(6)
                            }
                        }
                        if let location = item.purchaseLocation {
                            HStack {
                                Text("Purchased At:")
                                    .frame(width: 120, alignment: .leading)
                                Text(location)
                                    .padding(6)
                                    .background(Color(.systemGray4))
                                    .cornerRadius(6)
                            }
                        }
                        if let date = item.datePurchased {
                            HStack {
                                Text("Date:")
                                    .frame(width: 120, alignment: .leading)
                                Text(date)
                                    .padding(6)
                                    .background(Color(.systemGray4))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
                }
            }

            // MARK: Attention
            if item.attention {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel("Attention:")

                    Text(item.attentionDescription ?? "Needs attention")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }

    private func SectionLabel(_ title: String) -> some View {
        Text(title)
            .foregroundColor(.red)
            .bold()
    }
}
