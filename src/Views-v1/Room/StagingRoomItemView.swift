//
//  StagingRoomItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/8/25.
//

import CachedAsyncImage
import SwiftUI

struct StagingRoomItemView: View {
    @Environment(NavigationCoordinator.self) var coordinator
    @Environment(\.dismiss) private var dismiss
    @Binding var roomViewModel: RoomViewModel
    let item: Item
    @State var model: Model?
    let parentList: RDList
    let rooms: [Room]

    @State private var showQRCode: Bool = false
    @State private var qrCode: UIImage? = nil
    @State private var showInformation: Bool = false

    @State private var showOtherRoomSheet: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @State private var showRemoveConfirmationAlert: Bool = false
    
    // Image overlay variables
    @State private var selectedRDImage: RDImage? = nil
    @State private var isImageSelected: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar()
                    .padding(.horizontal, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Images()

                        ItemDetails()

                        ModelInformation()
                    }
                    .padding(.top, 4)
                    .frameHorizontalPadding()
                }

                Footer()
                    .frameHorizontalPadding()
            }
            .sheet(isPresented: $showOtherRoomSheet) {
                MoveItemRoomSheet(roomViewModel: $roomViewModel, alertMessage: $alertMessage, showAlert: $showAlert, parentList: parentList, item: item, rooms: rooms)
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    alertMessage = ""
                    dismiss()
                }
            }
            .frameTop()
            .frameBottomPadding()
            .toolbar(.hidden)
            .fullScreenCover(isPresented: $showQRCode) {
                if let model: Model = model {
                    ItemLabelView(item: item, model: model, )
                } else {
                    Text("Error loading item. Please try again.")
                }
            }
            .task {
                if model == nil {
                    model = await Item.getItemModel(modelId: item.modelId)
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
                Text("Item: ")
                    .bold()
                    .foregroundColor(.red)

                Text(model?.name ?? "Loading...")
            }
        }, trailingView: {
            Spacer().frame(32)
        })
    }

    // MARK: Images
    @ViewBuilder
    private func Images() -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Model Image:")
                    .bold()
                ModelImageView()
            }

            Spacer()

            VStack(spacing: 6) {
                Text("Item Image:")
                    .bold()
                ItemImageView()
            }
        }
    }

    // MARK: Item Details
    @ViewBuilder
    private func ItemDetails() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 0) {
                Text("Location: ")
                    .foregroundColor(.red)
                    .bold()

                Text(item.listId)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
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
            if model?.primaryImage.imageURL != nil {
                selectedRDImage = model?.primaryImage
                isImageSelected = true
            } else if let uiImage = model?.primaryImage.uiImage {
                selectedRDImage = RDImage(uiImage: uiImage)
                isImageSelected = true
            }
        } label: {
            if let model: Model = model, model.primaryImageExists {
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

    // MARK: Footer 
    @ViewBuilder
    private func Footer() -> some View {
        HStack(spacing: 12) {
            RDButton(variant: .default, size: .default, leadingIcon: SFSymbols.arrowUturnBackward, label: "Move to Other Room", fullWidth: true) {
                showOtherRoomSheet = true
            }
        }
    }
}
