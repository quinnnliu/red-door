//
//  PullListPDFContent.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/30/26.
//

import SwiftUI

/// Builds the blocks a pull list PDF is made of. This is the layer to change
/// when the document is redesigned — `PDFPaginator` and `PDFWriter` stay put.
struct PullListPDFContent {
    let pullList: PDFListInfo
    let rooms: [RoomV2]
    let itemsById: [String: ItemV2]
    let essentialsNamesById: [String: String]
    let preloadedImages: [String: UIImage]

    /// Sums to `PDFPaginator.contentWidth` minus the row's inter-column
    /// spacing. Retune here rather than on the individual cells.
    private enum Column {
        static let spacing: CGFloat = 6
        static let image: CGFloat = 44
        static let name: CGFloat = 110
        static let qrCode: CGFloat = 50
        static let type: CGFloat = 80
        static let dimensions: CGFloat = 110
        static let essential: CGFloat = 116
    }

    private enum Size {
        static let rowHeight: CGFloat = 50
        static let thumbnail: CGFloat = 44
    }

    // MARK: - Blocks

    func blocks() -> [PDFBlock] {
        var blocks: [PDFBlock] = [PDFBlock { ListSummary() }]

        for room in rooms {
            let items = room.itemIds
                .compactMap { itemsById[$0] }
                .sorted { $0.displayName < $1.displayName }

            blocks.append(PDFBlock(keepWithNext: true) { RoomTitle(room, itemCount: items.count) })

            guard !items.isEmpty else {
                blocks.append(PDFBlock { EmptyRoomNotice() })
                continue
            }

            blocks.append(PDFBlock(keepWithNext: true) { ColumnHeader() })
            for item in items {
                blocks.append(PDFBlock { ItemRow(item) })
            }
        }

        return blocks
    }

    // MARK: - Chrome

    /// Repeated on every page so a loose sheet still identifies its job.
    func chrome(page: Int, of total: Int) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(pullList.kindTitle) — \(pullList.baseName)")
                        .font(.system(size: 9, weight: .semibold))
                    Spacer()
                    Text("Page \(page) of \(total)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                Divider()
            }
            .padding(.bottom, 10)
        )
    }
}

// MARK: - Summary

private extension PullListPDFContent {

    func ListSummary() -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(pullList.address.formattedAddress)
                .font(.system(size: 15, weight: .bold))
                .padding(.bottom, 3)

            Text("Client: \(pullList.clientId)")
            Text("Install: \(pullList.installDate.displayDate)")
            Text("Uninstall: \(pullList.uninstallDate.displayDate)")
            Text("Rooms: \(rooms.count)    Items: \(totalItemCount)")
        }
        .font(.system(size: 9))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 16)
    }

    var totalItemCount: Int {
        rooms.reduce(0) { $0 + $1.itemIds.count }
    }
}

// MARK: - Room

private extension PullListPDFContent {

    func RoomTitle(_ room: RoomV2, itemCount: Int) -> some View {
        Text("\(room.displayName)  (\(itemCount))")
            .font(.system(size: 13, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    func EmptyRoomNotice() -> some View {
        Text("No items")
            .font(.system(size: 9))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
    }
}

// MARK: - Table

private extension PullListPDFContent {

    func ColumnHeader() -> some View {
        HStack(spacing: Column.spacing) {
            HeaderCell("Image", width: Column.image)
            HeaderCell("Name", width: Column.name)
            HeaderCell("Type", width: Column.type)
            HeaderCell("Dimensions", width: Column.dimensions)
            HeaderCell("Essentials Group", width: Column.essential)
            HeaderCell("QR", width: Column.qrCode, alignment: .center)
        }
        .frame(height: 18)
        .background(Color(white: 0.9))
        .overlay(Rectangle().stroke(Color(white: 0.7), lineWidth: 0.5))
    }

    func HeaderCell(_ title: String, width: CGFloat, alignment: Alignment = .leading) -> some View {
        Text(title)
            .font(.system(size: 8, weight: .bold))
            .frame(width: width, alignment: alignment)
    }

    func ItemRow(_ item: ItemV2) -> some View {
        HStack(spacing: Column.spacing) {
            Thumbnail(item)
                .frame(width: Column.image, alignment: .leading)

            Text(item.displayName)
                .font(.system(size: 8))
                .frame(width: Column.name, alignment: .leading)
                .lineLimit(3)

            Text(item.type.title)
                .font(.system(size: 8))
                .frame(width: Column.type, alignment: .leading)
                .lineLimit(2)

            OptionalCell(dimensionsText(item.dimensions), missing: "dimensions", width: Column.dimensions, lineLimit: 2)

            OptionalCell(essentialGroupName(item), missing: "essentials group", width: Column.essential, lineLimit: 3)

            QRCode(item)
                .frame(width: Column.qrCode, alignment: .center)
        }
        .frame(height: Size.rowHeight)
        .background(item.attention ? Color(white: 0.94) : Color.white)
        .overlay(Rectangle().stroke(Color(white: 0.8), lineWidth: 0.5))
    }

    /// The value, or a small gray "no <field> provided" when there isn't one.
    @ViewBuilder
    func OptionalCell(_ value: String?, missing field: String, width: CGFloat, lineLimit: Int) -> some View {
        Group {
            if let value {
                Text(value)
                    .font(.system(size: 8))
            } else {
                Text("no \(field) provided")
                    .font(.system(size: 6))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: width, alignment: .leading)
        .lineLimit(lineLimit)
    }

    /// "L × W × H unit", skipping any empty measurement. Nil when the item has
    /// no dimensions.
    func dimensionsText(_ dimensions: ItemDimensions?) -> String? {
        dimensions?.summary
    }

    /// Nil when the item isn't essential or its group failed to resolve.
    func essentialGroupName(_ item: ItemV2) -> String? {
        item.essentialGroupId.flatMap { essentialsNamesById[$0] }
    }

    @ViewBuilder
    func Thumbnail(_ item: ItemV2) -> some View {
        if let uiImage = preloadedImages[item.id] {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Size.thumbnail, height: Size.thumbnail)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: Size.thumbnail, height: Size.thumbnail)
        }
    }

    @ViewBuilder
    func QRCode(_ item: ItemV2) -> some View {
        if let qrCodeImage = item.id.generateQRCode() {
            Image(uiImage: qrCodeImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: Size.thumbnail, height: Size.thumbnail)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: Size.thumbnail, height: Size.thumbnail)
        }
    }
}

// MARK: - PDFListInfo

/// The list fields a PDF prints, so pull lists and installed lists share one
/// document layout.
struct PDFListInfo {
    let kindTitle: String
    let baseName: String
    let address: Address
    let clientId: String
    let installDate: Date
    let uninstallDate: Date

    init(_ list: PullListV2) {
        kindTitle = "Pull List"
        baseName = list.baseName
        address = list.address
        clientId = list.clientId
        installDate = list.installDate
        uninstallDate = list.uninstallDate
    }

    init(_ list: InstalledListV2) {
        kindTitle = "Installed List"
        baseName = list.baseName
        address = list.address
        clientId = list.clientId
        installDate = list.installDate
        uninstallDate = list.uninstallDate
    }
}
