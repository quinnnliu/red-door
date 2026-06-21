//
//  AddItemToDocumentDetailView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import SwiftUI

struct AddItemToDocumentDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: AddItemToDocumentDetailViewModel
    @State private var showInformation: Bool = false

    init(context: AddItemDocumentContext) {
        viewModel = AddItemToDocumentDetailViewModel(context: context)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                DragIndicator()

                TopBar
                    .frameHorizontalPadding()

                ScrollView {
                    VStack(spacing: 12) {
                        PrimaryImageView(image: viewModel.context.item.primaryImage)

                        VStack(spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    showInformation.toggle()
                                }
                            } label: {
                                HStack(spacing: 0) {
                                    Text("Information")
                                        .foregroundColor(.white)
                                        .bold()

                                    Spacer()

                                    Image(systemName: showInformation ? SFSymbols.chevronUp : SFSymbols.chevronDown)
                                        .foregroundColor(.white)
                                }
                                .padding(8)
                                .background(.red)
                                .cornerRadius(6)
                            }

                            if showInformation {
                                ItemDetailSection(item: viewModel.context.item)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .padding(.top, 4)
                    .frameHorizontalPadding()
                }

                Spacer()

                RDButton(
                    variant: .red,
                    leadingIcon: SFSymbols.plus,
                    iconBold: true,
                    label: "Add to \(viewModel.context.destination.displayName)",
                    fullWidth: true
                ) {
                    Task {
                        await viewModel.addItem()
                        dismiss()
                    }
                }
                .frameHorizontalPadding()
            }
            .frameTop()
            .frameBottomPadding()
            .toolbar(.hidden)
            .alert(viewModel.alertText, isPresented: $viewModel.showAlert) {
                Button("OK") { }
            }

            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Saving...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
            }
        }
    }

    // MARK: - Top Bar

    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton()
            },
            header: {
                HStack {
                    Text("Name:")
                        .font(.headline)
                    Text(viewModel.context.item.displayName)
                }
            },
            trailingView: {
                EmptyView()
            }
        )
    }
}
