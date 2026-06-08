//
//  PullListItemDetailsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/5/26.
//

import CachedAsyncImage
import SwiftUI

struct PullListItemDetailView: View {
	@Environment(NavigationCoordinator.self) var coordinator
	@Environment(\.dismiss) private var dismiss

	@State var viewModel: PullListItemDetailsViewModel

	@State private var showInformation: Bool = false
    @State private var showQRCodeSheet: Bool = false

	init(
		item: ItemV2,
        room: RoomV2
	) {
		self.viewModel = PullListItemDetailsViewModel(
			item: item,
            room: room
		)
	}
    
	// MARK: - Body

	var body: some View {
		ZStack {
			VStack(spacing: 12) {
				TopBar
					.padding(.horizontal, 16)

				ScrollView {
					VStack(spacing: 12) {
                        ItemImageView

						ItemDetails

                        ItemDetailSection(item: viewModel.itemState)
					}
					.padding(.top, 4)
					.frameHorizontalPadding()
				}

				Footer()
					.frameHorizontalPadding()
			}
            .fullScreenCover(isPresented: $showQRCodeSheet) {
                ItemV2LabelView(item: viewModel.itemState)
            }
            .sheet(isPresented: $viewModel.showMoveItemSheet) {
                SelectDocumentSheet(title: "Other Rooms", documents: viewModel.rooms.filter { $0.id != viewModel.room.id }, action: handleAction(_:))
                    .task { await viewModel.fetchRoomsForMove() }
			}
			.alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
				Button("OK", role: .cancel) {
					viewModel.alertMessage = ""
					dismiss()
				}
			}
			.alert("Remove Item", isPresented: $viewModel.showRemoveConfirmationAlert) {
				Button("Remove", role: .destructive) {
					Task {
						let success = await viewModel.removeItemFromRoom()
						if success {
							dismiss()
						}
					}
				}
				Button("Cancel", role: .cancel) {
					viewModel.showRemoveConfirmationAlert = false
				}
			} message: {
				Text("Are you sure you want to remove this item from \(viewModel.room.displayName)?")
			}
			.frameTop()
			.frameBottomPadding()
			.toolbar(.hidden)
			.fullScreenCover(isPresented: $viewModel.showQRCode) {
                ItemV2LabelView(item: viewModel.itemState)
			}
			.overlay(
				ModelRDImageOverlay(selectedRDImage: viewModel.selectedRDImage, isImageSelected: $viewModel.isImageSelected)
					.animation(.easeInOut(duration: 0.3), value: viewModel.isImageSelected)
			)
		}
	}
    
    // MARK: - Action Handling

    private func handleAction(_ action: Any?) {
        guard let action else { return }
        switch action {
        case let sheetAction as SelectDocumentSheetAction<RoomV2>:
            switch sheetAction {
            case .selected(let newRoom):
                Task { await viewModel.moveItemToNewRoom(newRoom: newRoom) }
            }
        default:
            break
        }
    }

	// MARK: - Top Bar

    private var TopBar: some View {
		TopAppBar(leadingView: {
			BackButton()
		}, header: {
			HStack(spacing: 0) {
				Text("Item: ")
					.bold()
					.foregroundColor(.red)

				Text(viewModel.itemState.displayName)
			}
		}, trailingView: {
            RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.qrcode) {
                showQRCodeSheet = true
            }
            .clipShape(.circle)
		})
	}

	// MARK: - Item Details

    private var ItemDetails: some View {
		VStack(alignment: .leading, spacing: 12) {
            if viewModel.itemState.status != .inStorage {
                HStack(alignment: .center, spacing: 0) {
                    Text("Location: ")
                        .foregroundColor(.red)
                        .bold()

                    if let address = viewModel.pullList?.address.getStreetAddress() ?? viewModel.pullList?.address.formattedAddress {
                        Text(address)
                    } else {
                        Text(viewModel.pullList?.address.getStreetAddress() ?? "Loading...")
                            .task {
                                await viewModel.fetchPullListForLocation()
                            }
                    }
                }
            }

			HStack(alignment: .center, spacing: 0) {
				Text("ID: ")
					.foregroundColor(.red)
					.bold()

                Text(viewModel.itemState.id)
					.font(.caption)
			}

			VStack(alignment: .leading, spacing: 8) {
				HStack(alignment: .center, spacing: 4) {
					Text("Needs Attention: ")
						.foregroundColor(.red)
						.bold()

					Image(systemName: SFSymbols.exclamationmarkTriangleFill)
                        .foregroundColor(viewModel.itemState.attention ? .yellow : .gray)
				}

				if let attentionDescription = viewModel.itemState.attentionDescription, viewModel.itemState.attention {
                    Text(attentionDescription)
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
    
	// MARK: - Model Information

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

                        Image(systemName: showInformation ? SFSymbols.chevronUp : SFSymbols.chevronDown)
							.foregroundColor(.white)
					}
					.padding(8)
					.background(.red)
					.cornerRadius(6)
				}

				Spacer()

				SmallCTA(type: .red, leadingIcon: SFSymbols.qrcode, text: "Label") {
					viewModel.showQRCode = true
				}
			}
		}
	}
    
	// TODO: abstract this to avoid duplicate code
	// MARK: - Item Image View

    private var ItemImageView: some View {
		Button {
			if viewModel.itemState.primaryImage.imageURL != nil {
				viewModel.selectedRDImage = viewModel.itemState.primaryImage
			} else if let uiImage = viewModel.itemState.primaryImage.uiImage {
				viewModel.selectedRDImage = RDImage(uiImage: uiImage)
			}
			viewModel.isImageSelected = true
		} label: {
            CachedAsyncImage(url: viewModel.itemState.primaryImage.imageURL) { image in
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
		}
		.buttonStyle(PlainButtonStyle())
	}

	// MARK: - Footer

	@ViewBuilder
	private func Footer() -> some View {
		HStack(spacing: 12) {
            RDButton(variant: .default, size: .default, leadingIcon: SFSymbols.arrowUturnBackward, label: "Move to Other Room", fullWidth: true, font: .caption2) {
				viewModel.showMoveItemSheet = true
			}

            RDButton(variant: .red, size: .default, leadingIcon: SFSymbols.trash, label: "Remove from \(viewModel.room.displayName)", fullWidth: true, font: .caption2) {
				viewModel.showRemoveConfirmationAlert = true
			}
		}
	}
}

