//
//  ItemDetailsViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/14/26.
//

import SwiftUI

struct ItemDetailsViewV2: View {
    @State private var viewModel: ItemDetailViewModel
    @State private var showEditItem: Bool = false
    @State private var showQRCodeLabel: Bool = false


    init(viewModel: ItemDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                TopBar()
                if let nickname = viewModel.itemState.nickname {
                    Text("Nickname: \(nickname)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    PrimaryImageView(image: viewModel.itemState.primaryImage)
                    
                    ItemDetails
                }
                .padding(.top, 4)
            }
        }
        .frameTop()
        .frameHorizontalPadding()
        .toolbar(.hidden)
        .onAppear { viewModel.startListening() }
        .task(id: viewModel.itemState.essentialGroupId) {
            await viewModel.loadEssentialsGroup()
        }
        .fullScreenCover(isPresented: $showEditItem) {
            ItemViewFactory().makeEditItemView(
                item: viewModel.itemState,
                essentialsGroup: viewModel.essentialsGroup
            )
        }
        .fullScreenCover(isPresented: $showQRCodeLabel) {
            ItemV2LabelView(item: viewModel.itemState)
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
                    Text("Item:")
                        .bold()
                        .foregroundStyle(.red)
                    Text(viewModel.itemState.displayName)
                }
            },
            trailingView: {
                TopBarMenu
            }
        )
    }
}

private extension ItemDetailsViewV2 {
    
    // MARK: - Top Bar Menu

    var TopBarMenu: some View {
        Menu {
            Button("Edit", systemImage: SFSymbols.pencil) {
                showEditItem = true
            }

            Button("Label", systemImage: SFSymbols.qrcode) {
                showQRCodeLabel = true
            }
        } label: {
            RDButton(
                style: .red,
                size: .icon,
                leadingIcon: SFSymbols.ellipsis
            ) { }.clipShape(.circle)
        }
        .tint(.red)
    }

    var ItemDetails: some View {
        VStack(spacing: 12) {
            ItemDetailSection(
                item: viewModel.itemState,
                essentialsGroup: viewModel.essentialsGroup
            )
        }
    }
}
