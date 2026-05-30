//
//  ItemDetailView.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/8/25.
//

import CachedAsyncImage
import SwiftUI

struct ItemDetailView: View {
    @Environment(NavigationCoordinator.self) var coordinator
    @State private var viewModel: ItemViewModel
    @State private var model: Model? = nil
    @State private var list: RDList? = nil

    @State private var showEditSheet: Bool = false
    @State private var backupItem: Item? = nil

    @State private var showQRCode: Bool = false
    @State private var qrCode: UIImage? = nil

    @State private var showInformation: Bool = false
    
    // Image overlay variables
    @State private var selectedRDImage: RDImage? = nil
    @State private var isImageSelected: Bool = false


    init(item: Item, model: Model? = nil, list: RDList? = nil) {
        viewModel = ItemViewModel(selectedItem: item)
        self.model = model
        self.list = list
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar()
                    .padding(.horizontal, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // MARK: Model and Item Images
                        HStack(spacing: 0) {
                            VStack(spacing: 6) {
                                Text("Model Image:")
                                    .foregroundColor(.red)
                                    .bold()
                                ModelImageView()
                            }

                            Spacer()

                            VStack(spacing: 6) {
                                Text("Item Image:")
                                    .foregroundColor(.red)
                                    .bold()
                                ItemImage(itemImage: $viewModel.selectedItem.image, isEditing: false, selectedRDImage: $selectedRDImage, isImageSelected: $isImageSelected)
                            }
                        }

                        ItemDetails()

                        ModelInformation()
                    }
                    .padding(.top, 4)
                    .frameHorizontalPadding()
                }
            }
            .frameTop()
            .toolbar(.hidden)
            .fullScreenCover(isPresented: $showQRCode) {
                if let model: Model = model {
                    ItemLabelView(item: viewModel.selectedItem, model: model, )
                } else {
                    Text("Error loading item. Please try again.")
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let model: Model = model {
                    EditItemSheet(viewModel: $viewModel, model: model)
                } else {
                    Text("Error loading item. Please try again.")
                }
            }
            .task {
                if model == nil {
                    model = await Item.getItemModel(modelId: viewModel.selectedItem.modelId)
                }
                if !viewModel.selectedItem.isAvailable && list == nil {
                    list = await RDList.getList(listId: viewModel.selectedItem.listId)
                }
            }
            .overlay(
                ModelRDImageOverlay(selectedRDImage: selectedRDImage, isImageSelected: $isImageSelected)
                    .animation(.easeInOut(duration: 0.3), value: isImageSelected)
            )
        }
    }

    // MARK: Top Bar

    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(leadingView: {
            BackButton()
        }, header: {
            HStack(spacing: 0) {
                Text("(Item) Model: ")
                    .font(.headline)
                    .foregroundColor(.red)

                Text(model?.name ?? "Loading...")
            }
        }, trailingView: {
            RDButton(variant: .red, size: .icon, leadingIcon: "square.and.pencil", fullWidth: false) {
                showEditSheet = true
                backupItem = viewModel.selectedItem
            }
            .clipShape(Circle())
        })
    }

    // MARK: Item Details
    @ViewBuilder
    private func ItemDetails() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Description:")
                    .foregroundColor(.red)
                    .bold()

                Group {
                    if let model: Model = model {
                        Text(model.description)
                    } else {
                        Text("No description")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.primary)
                .padding(6)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }

            HStack(alignment: .center, spacing: 0) {
                Text("Location: ")
                    .foregroundColor(.red)
                    .bold()

                if viewModel.selectedItem.isAvailable {
                    Text(viewModel.selectedItem.listId)
                } else {
                    if let list = list {
                        NavigationLink(value: list) {
                            Text(list.address.getStreetAddress() ?? "Loading...")
                        }
                    } else {
                        Text("Loading...")
                            .font(.caption)
                            .padding(8)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                    }
                }
            }

            HStack(alignment: .center, spacing: 0) {
                Text("ID: ")
                    .foregroundColor(.red)
                    .bold()
                
                Text(viewModel.selectedItem.id)
                    .font(.caption)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 4) {
                    Text("Needs Attention: ")
                        .foregroundColor(.red)
                        .bold()
                    
                    Image(systemName: SFSymbols.exclamationmarkTriangleFill)
                        .foregroundColor(viewModel.selectedItem.attention ? .yellow : .gray)
                }

                if viewModel.selectedItem.attention {
                    Text(viewModel.selectedItem.attentionReason)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                }
            }
        }
    }

    // MARK: Model Information
    @ViewBuilder
    private func ModelInformation() -> some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showInformation.toggle()
                    }
                }) {
                    HStack(spacing: 0) {
                        Text("Model Information")
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

                Spacer()

                SmallCTA(type: .red, leadingIcon: SFSymbols.qrcode, text: "Label") {
                    showQRCode = true
                }
            }

            if showInformation {
                if let model: Model = model {
                    ModelInformationView(model: model)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    Text("Error loading model. Please try again.")    
                }
            }
        }
    }

    // MARK: Model Image View

    @ViewBuilder
    private func ModelImageView() -> some View {
        Button {
            if let model = model {
                if model.primaryImage.imageURL != nil {
                    selectedRDImage = model.primaryImage
                } else if let uiImage = model.primaryImage.uiImage {
                    selectedRDImage = RDImage(uiImage: uiImage)
                }
                isImageSelected = true
            }
        } label: {
            if let model: Model = model {
                CachedAsyncImage(url: model.primaryImage.imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(Constants.screenWidthPadding / 2)
                        .cornerRadius(8)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundColor(Color(.systemGray5))
                        .frame(Constants.screenWidthPadding / 2)
                        .overlay(Image(systemName: SFSymbols.photoBadgePlus)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.secondary)
                        )
                }
                
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(Color(.systemGray5))
                    .frame(Constants.screenWidthPadding / 2)
                    .overlay(Image(systemName: SFSymbols.photoBadgePlus)
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.secondary)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
