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

    private let itemRepository = ItemRepository()
    private let roomRepository: RoomRepository<PullListV2>

    init(list: PullListV2) {
        self.roomRepository = RoomRepository(list: list)
        self.list = list
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BackButton()

            VStack(alignment: .center, spacing: 0) {
                if let pdfDocument {
                    PDFKitView(document: pdfDocument)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray, lineWidth: 1)
                        )

                    if let pdfData {
                        ShareButton(pdfData)
                    }
                } else {
                    Spacer()
                    if let errorMessage {
                        ErrorState(errorMessage)
                    } else {
                        LoadingState
                    }
                    Spacer()
                }
            }
        }
        .task {
            await generatePDF()
        }
        .frameTop()
        .frameHorizontalPadding()
    }
}

// MARK: - States

private extension PullListPDFViewV2 {

    var LoadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Generating PDF")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func ErrorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(.red)
            Text("Error generating PDF")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func ShareButton(_ data: Data) -> some View {
        ShareLink(
            item: PDFFile(data: data),
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

// MARK: - Generation

private extension PullListPDFViewV2 {

    @MainActor
    func generatePDF() async {
        isGeneratingPDF = true
        errorMessage = nil
        defer { isGeneratingPDF = false }

        do {
            let rooms = try await fetchRooms()
            let itemsById = try await fetchItems(for: rooms)
            let images = await preloadImages(for: itemsById)

            let content = PullListPDFContent(
                pullList: list,
                rooms: rooms,
                itemsById: itemsById,
                preloadedImages: images
            )

            let paginator = PDFPaginator()
            let pages = paginator.paginate(content.blocks()) { page, total in
                content.chrome(page: page, of: total)
            }

            let data = try PDFWriter.data(pages: pages, pageSize: paginator.pageSize)
            guard let document = PDFDocument(data: data) else {
                throw PDFWriterError.emptyDocument
            }

            pdfData = data
            pdfDocument = document
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchRooms() async throws -> [RoomV2] {
        guard !list.roomIds.isEmpty else { return [] }
        return try await roomRepository
            .get(ids: list.roomIds)
            .sorted { $0.displayName < $1.displayName }
    }

    /// One fetch for the whole list rather than one per room, so items shared
    /// across rooms are only read once.
    func fetchItems(for rooms: [RoomV2]) async throws -> [String: ItemV2] {
        let ids = Array(Set(rooms.flatMap(\.itemIds)))
        let items = try await itemRepository.get(ids: ids)

        var byId: [String: ItemV2] = [:]
        for item in items { byId[item.id] = item }
        return byId
    }

    /// Downloads concurrently: a full list serially fetching one image at a
    /// time dominated generation time.
    func preloadImages(for itemsById: [String: ItemV2]) async -> [String: UIImage] {
        await withTaskGroup(of: (String, UIImage)?.self) { group in
            for (itemId, item) in itemsById {
                guard let imageURL = item.primaryImage.thumbnailURL ?? item.primaryImage.imageURL else { continue }
                group.addTask {
                    guard let (data, _) = try? await URLSession.shared.data(from: imageURL),
                          let image = UIImage(data: data)
                    else { return nil }
                    return (itemId, image)
                }
            }

            var result: [String: UIImage] = [:]
            for await entry in group {
                if let entry { result[entry.0] = entry.1 }
            }
            return result
        }
    }
}
