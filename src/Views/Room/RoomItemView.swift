//
//  RoomItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 2/23/25.
//

import SwiftUI
import CachedAsyncImage

struct RoomItemView: View {
    @Environment(\.dismiss) private var dismiss
    let item: Item
    let model: Model
    @Binding var roomViewModel: RoomViewModel

    @State private var showInformation = false
    @State private var showItemAddedAlert = false
    @State private var itemAddedAlertMessage: String = ""
    @State private var showQRCode = false

    // Image overlay variables
    @State private var selectedRDImage: RDImage? = nil
    @State private var isImageSelected: Bool = false

    // MARK: Body
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                DragIndicator()

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
                                ItemImageView()
                            }
                        }

                        ItemDetails()

                        ModelInformation()

                        
                    }
                    .padding(.top, 4)
                    .frameHorizontalPadding()
                }

                Spacer()

                RDButton(variant: .red, size: .default, leadingIcon: SFSymbols.plus, iconBold: true, label: "Add Item to room", fullWidth: true) {
                    Task {
                        let added = await roomViewModel.addItemToRoom(item: item)
                        if added {
                            itemAddedAlertMessage = "Item added to \(roomViewModel.selectedRoom.roomName)"
                        } else {
                            itemAddedAlertMessage = "Item has already been added to this pull list."
                        }
                        showItemAddedAlert = true
                    }
                }
                .frameHorizontalPadding()
            }
            .frameTop()
            .toolbar(.hidden)
            .alert(itemAddedAlertMessage, isPresented: $showItemAddedAlert) {
                Button("OK", role: .cancel) {
                    showItemAddedAlert = false
                    itemAddedAlertMessage = ""
                }
            }
            .fullScreenCover(isPresented: $showQRCode) {
                ItemLabelView(item: item, model: model)
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
        TopAppBar(
            leadingIcon: {
                BackButton()
            }, header: {
                HStack(spacing: 0) {
                    Text("(Item) Model: ")
                        .font(.headline)
                        .foregroundColor(.red)

                    Text(model.name)
                }
            }, trailingIcon: {
                Spacer().frame(32)
            }
        )
    }

    // MARK: Item Details
    @ViewBuilder
    private func ItemDetails() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 0) {
                Text("Location: ")
                    .foregroundColor(.red)
                    .bold()

                if item.isAvailable {
                    Text(item.listId)
                } else {
                    Text("Not Available") // shouldn't be able to navigate here
                }
            }

            HStack(alignment: .center, spacing: 0) {
                Text("ID: ")
                    .foregroundColor(.red)
                    .bold()
                
                Text(item.id)
                    .font(.caption)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 4) {
                    Text("Needs Attention: ")
                        .foregroundColor(.red)
                        .bold()
                    
                    Image(systemName: SFSymbols.exclamationmarkTriangleFill)
                        .foregroundColor(item.attention ? .yellow : .gray)
                }

                if item.attention {
                    Text(item.attentionReason)
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
                ModelInformationView(model: model)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: Model Image View
    @ViewBuilder
    private func ModelImageView() -> some View {
        Button {
            if model.primaryImage.imageURL != nil {
                selectedRDImage = model.primaryImage
            } else if let uiImage = model.primaryImage.uiImage {
                selectedRDImage = RDImage(uiImage: uiImage)
            }
            isImageSelected = true
        } label: {
            if model.primaryImageExists {
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

    // TODO: abstract this to avoid duplicate code
    // MARK: Item Image View

    @ViewBuilder
    private func ItemImageView() -> some View {
        Button {
            if let image = item.image, image.imageURL != nil {
                selectedRDImage = image
            } else if let uiImage = item.image?.uiImage {
                selectedRDImage = RDImage(uiImage: uiImage)
            }
            isImageSelected = true
        } label: {
            if let image = item.image, image.imageExists {
                CachedAsyncImage(url: image.imageURL) { image in
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

