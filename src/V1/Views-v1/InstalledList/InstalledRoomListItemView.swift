//
//  InstalledRoomListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/13/25.
//

import CachedAsyncImage
import SwiftUI

struct InstalledRoomListItemView: View {
    // MARK: init Variables

    @State private var viewModel: RoomViewModel

    init(room: Room) {
        _viewModel = State(initialValue: RoomViewModel(room: room))
    }

    @State private var showRoomPreview: Bool = false

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoomPreviewHeader()
            
            if showRoomPreview {
                RoomPreview()
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(6)
        .task {
            await viewModel.loadItemsAndModels()
        }
    }

    // MARK: Room Preview Header

    @ViewBuilder
    private func RoomPreviewHeader() -> some View {
        HStack(spacing: 12) {
            RDButton(variant: .outline, size: .icon, leadingIcon: showRoomPreview ? SFSymbols.minus : SFSymbols.plus, iconBold: true, fullWidth: false) {
                showRoomPreview.toggle()
            }
            .disabled(viewModel.selectedRoom.itemModelIdMap.isEmpty)
            
            Text(viewModel.selectedRoom.roomName)
                .foregroundColor(.primary)
                .bold()

            Spacer()

            (
                Text("Items: ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                +
                Text("\(viewModel.items.count)")
                    .font(.caption)
                    .foregroundColor(.red)
            )
        }
    }

    // MARK: Room Preview

    @ViewBuilder
    private func RoomPreview() -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 8) {
            ForEach(viewModel.items, id: \.self) { item in
                ItemListItem(item: item)
            }
        }
        .task {
            if viewModel.selectedRoom.itemModelIdMap.isEmpty {
                await viewModel.getRoomModels()
            }
        }
    }

    // MARK: Item List Item

    @ViewBuilder
    private func ItemListItem(item: Item) -> some View {
        let model: Model? = viewModel.getModelForItem(item)

        NavigationLink(value: item) {
            HStack(alignment: .center, spacing: 12) {            
                ItemModelImage(item: item, model: model)

                VStack(alignment: .leading, spacing: 4) {
                    Text(model?.name ?? "No Model Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: 4) {
                        Image(systemName: Model.typeMap[model?.type ?? ""] ?? "nosign")
                            .foregroundColor(.secondary)

                        Image(systemName: SFSymbols.circleFill)
                            .foregroundColor(Model.colorMap[model?.primaryColor ?? ""] ?? .black)
                    }
                    .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(item.attention ? Color.yellow.opacity(0.75) : item.isAvailable ? Color(.systemGray3) : Color.red, lineWidth: 2)
            )
        }
    }
}