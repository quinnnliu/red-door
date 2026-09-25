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
    @State private var showMoveRoomSheet: Bool = false

    init(item: ItemV2, destination: AddItemsToListableDestination) {
        viewModel = AddItemToDocumentDetailViewModel(item: item, destination: destination)
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
                        PrimaryImageView(image: viewModel.item.primaryImage)

                        VStack(spacing: 12) {
                            Button {
                                withAnimation(Constants.Animation.snappy) {
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
                                ItemDetailSection(item: viewModel.item)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .padding(.top, 4)
                    .frameHorizontalPadding()
                }

                Spacer()

                VStack(spacing: 8) {
                    if case .room = viewModel.destination {
                        RDButton(variant: .outline, label: "Move to Another Room", fullWidth: true) {
                            showMoveRoomSheet = true
                        }
                    }

                    RDButton(
                        variant: .red,
                        leadingIcon: SFSymbols.plus,
                        iconBold: true,
                        label: "Add to \(viewModel.destination.document.displayName)",
                        fullWidth: true
                    ) {
                        Task {
                            await viewModel.addItem()
                            dismiss()
                        }
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
            .sheet(isPresented: $showMoveRoomSheet) {
                if case .room(let room) = viewModel.destination {
                    MoveItemV2RoomSheet(room: room, item: viewModel.item)
                }
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
                    Text(viewModel.item.displayName)
                }
            },
            trailingView: {
                EmptyView()
            }
        )
    }
}
