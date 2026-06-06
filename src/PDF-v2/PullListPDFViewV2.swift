//
//  PullListPDFViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/5/26.
//

import Foundation
import PDFKit
import SwiftUI

struct PullListPDFViewV2: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pdfDocument: PDFDocument? = nil
    @State private var isGeneratingPDF: Bool = false
    @State private var pdfData: Data? = nil
    @State private var errorMessage: String? = nil

    let list: PullListV2

    private let pullListRepository = PullListRepository()
    private let itemRepository = ItemRepository()

    init(list: PullListV2) {
        self.list = list
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BackButton()

            VStack(alignment: .center, spacing: 0) {
                if pdfDocument == nil {
                    Spacer()

                    if let errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundStyle(.red)
                            Text("Error generating PDF")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Generating PDF")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    Spacer()
                } else {
                    PDFKitView(document: pdfDocument!)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray, lineWidth: 1)
                        )

                    if isGeneratingPDF {
                        ProgressView("Preparing PDF for export...")
                            .padding()
                    }

                    if #available(iOS 17, *), let pdfData {
                        ShareLink(
                            item: PDFFile(data: pdfData),
                            preview: SharePreview(
                                "(PullList) \(list.address.formattedAddress).pdf",
                                image: Image(systemName: SFSymbols.docFill)
                            ),
                            label: {
                                HStack(spacing: 8) {
                                    Image(systemName: SFSymbols.squareAndArrowUp)
                                        .font(.system(size: 16))
                                        .fontWeight(.bold)

                                    Text("Share / Export PDF")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color(.red))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        )
                        .padding()
                    }
                }
            }
        }
        .task {
            await generatePDF()
        }
        .frameTop()
        .frameHorizontalPadding()
    }

    @MainActor
    private func generatePDF() async {
        do {
            isGeneratingPDF = true
            errorMessage = nil

            let rooms = try await fetchRooms()
            let itemsById = try await fetchItems(for: rooms)
            let preloadedImages = await preloadImages(for: itemsById)

            let pdfView = PLGeneratedPDFViewV2(
                pullList: list,
                rooms: rooms,
                itemsById: itemsById,
                preloadedImages: preloadedImages
            )

            let renderer = ImageRenderer(content: pdfView)
            renderer.proposedSize = .init(width: 850, height: 1100)

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".pdf")

            renderer.render { size, context in
                var box = CGRect(origin: .zero, size: size)
                guard let pdf = CGContext(tempURL as CFURL, mediaBox: &box, nil) else { return }

                pdf.beginPDFPage(nil)
                context(pdf)
                pdf.endPDFPage()
                pdf.closePDF()
            }

            if let data = try? Data(contentsOf: tempURL) {
                pdfData = data
                pdfDocument = PDFDocument(data: data)
            }

            try? FileManager.default.removeItem(at: tempURL)

            isGeneratingPDF = false
        } catch {
            errorMessage = error.localizedDescription
            isGeneratingPDF = false
        }
    }

    private func fetchRooms() async throws -> [RoomV2] {
        guard !list.roomIds.isEmpty else { return [] }
        guard let roomRepository = RoomRepository(list: list) else {
            throw NSError(domain: "RoomRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize RoomRepository"])
        }
        return try await roomRepository.get(ids: list.roomIds)
    }

    private func fetchItems(for rooms: [RoomV2]) async throws -> [String: ItemV2] {
        var itemsById: [String: ItemV2] = [:]
        for room in rooms {
            let items = try await itemRepository.get(ids: Array(room.itemIds))
            for item in items {
                itemsById[item.id] = item
            }
        }
        return itemsById
    }

    private func preloadImages(for itemsById: [String: ItemV2]) async -> [String: UIImage] {
        var result: [String: UIImage] = [:]

        for (itemId, item) in itemsById {
            if let imageURL = item.primaryImage.imageURL {
                do {
                    let (data, _) = try await URLSession.shared.data(from: imageURL)
                    if let image = UIImage(data: data) {
                        result[itemId] = image
                    }
                } catch {
                    print("Failed to preload image for item \(itemId): \(error)")
                }
            }
        }
        return result
    }
}
