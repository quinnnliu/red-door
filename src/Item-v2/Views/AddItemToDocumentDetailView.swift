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
    @State private var showMoveRoomSheet: Bool = false
    @State private var showQRCodeSheet: Bool = false

    init(item: ItemV2, destination: AddItemsToListableDestination) {
        viewModel = AddItemToDocumentDetailViewModel(item: item, destination: destination)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                DragIndicator()

                TopBar

                ScrollView {
                    VStack(spacing: 12) {
                        PrimaryImageView(image: viewModel.item.primaryImage)

                        ItemDetailSection(
                            item: viewModel.item,
                            essentialsGroup: viewModel.essentialsGroup
                        )
                        .task { await viewModel.loadEssentialsGroup() }
                    }
                    .padding(.top, 4)
                }

                Spacer(minLength: .zero)

                RDButton(
                    variant: .red,
                    leadingIcon: SFSymbols.plus,
                    label: "Add to \(viewModel.destination.document.displayName)",
                    fullWidth: true
                ) {
                    Task {
                        await viewModel.addItem()
                        dismiss()
                    }
                }
            }
            .frameTop()
            .frameBottomPadding()
            .frameHorizontalPadding()
            .toolbar(.hidden)
            .alert(viewModel.alertText, isPresented: $viewModel.showAlert) {
                Button("OK") { }
            }
            .fullScreenCover(isPresented: $showQRCodeSheet) {
                ItemV2LabelView(item: viewModel.item)
            }
            .sheet(isPresented: $showMoveRoomSheet) {
                if case .room(let room, let listKind) = viewModel.destination {
                    MoveItemV2RoomSheet(room: room, item: viewModel.item, listKind: listKind)
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
                RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.qrcode) {
                    showQRCodeSheet = true
                }
                .clipShape(.circle)
            }
        )
    }
}
