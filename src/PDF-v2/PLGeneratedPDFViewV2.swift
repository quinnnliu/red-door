//
//  PLGeneratedPDFViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/5/26.
//

import SwiftUI

struct PLGeneratedPDFViewV2: View {
    let pullList: PullListV2
    let rooms: [RoomV2]
    let itemsById: [String: ItemV2]
    let preloadedImages: [String: UIImage]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Header()

            VStack(alignment: .leading, spacing: 20) {
                ForEach(rooms, id: \.id) { room in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Room: \(room.displayName)")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 20)

                        let roomItems = room.itemIds.compactMap { itemsById[$0] }
                        if !roomItems.isEmpty {
                            VStack(spacing: 0) {
                                RoomHeader()

                                ForEach(roomItems, id: \.id) { item in
                                    ItemRow(item: item)
                                }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            Text("No items found")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }

            Spacer()
        }
        .frame(width: 850, height: 1100)
        .background(Color.white)
    }

    // MARK: - Header

    @ViewBuilder
    private func Header() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pull List: \(pullList.address.formattedAddress)")
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, 6)
            Text("Client: \(pullList.clientId)")
                .font(.system(size: 12))
            Text("Install Date: \(pullList.installDate)")
                .font(.system(size: 12))
            Text("Uninstall Date: \(pullList.uninstallDate)")
                .font(.system(size: 12))
        }
        .padding(.top, 40)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Room Header

    @ViewBuilder
    private func RoomHeader() -> some View {
        HStack(spacing: 0) {
            Text("Image")
                .font(.system(size: 10, weight: .bold))
                .frame(width: 60, alignment: .leading)
                .padding(.leading, 6)

            Text("Name")
                .font(.system(size: 10, weight: .bold))
                .frame(width: 120, alignment: .leading)
                .padding(.leading, 6)

            Text("Item ID")
                .font(.system(size: 10, weight: .bold))
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 6)

            Text("Type")
                .font(.system(size: 10, weight: .bold))
                .frame(width: 130, alignment: .leading)
                .padding(.leading, 6)

            Text("Location")
                .font(.system(size: 10, weight: .bold))
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 6)

            Text("Essential")
                .font(.system(size: 10, weight: .bold))
                .frame(width: 80, alignment: .center)

            Text("QR Code")
                .font(.system(size: 10, weight: .bold))
                .frame(width: 80, alignment: .center)
        }
        .frame(height: 25)
        .background(Color(white: 0.9))
        .overlay(Rectangle().stroke(Color(white: 0.7), lineWidth: 1))
    }

    // MARK: - Item Row

    @ViewBuilder
    private func ItemRow(item: ItemV2) -> some View {
        HStack(spacing: 0) {
            ItemImage(item)
                .frame(width: 50, height: 50, alignment: .center)
                .padding(.leading, 6)

            Text(item.name)
                .font(.system(size: 9))
                .frame(width: 120, alignment: .leading)
                .padding(.leading, 6)
                .lineLimit(2)

            Text(item.id)
                .font(.system(size: 9))
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 6)
                .lineLimit(2)

            Text(item.type.title)
                .font(.system(size: 9))
                .frame(width: 130, alignment: .leading)
                .padding(.leading, 6)
                .lineLimit(1)

            Text(item.listId ?? "—")
                .font(.system(size: 9))
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 6)
                .lineLimit(2)

            Image(systemName: item.isEssential ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundColor(item.isEssential ? .green : .gray)
                .frame(width: 80, alignment: .center)

            if let qrCodeImage = item.id.generateQRCode() {
                Image(uiImage: qrCodeImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .frame(width: 80, alignment: .center)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .frame(width: 80, alignment: .center)
            }
        }
        .frame(height: 60)
        .background(Color.white)
        .overlay(Rectangle().stroke(Color(white: 0.8), lineWidth: 1))
    }

    // MARK: - Item Image

    @ViewBuilder
    private func ItemImage(_ item: ItemV2) -> some View {
        if let uiImage = preloadedImages[item.id] {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
        }
    }
}
