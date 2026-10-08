//
//  PullListPDFViewModelV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/05/26.
//

import Foundation
import PDFKit
import SwiftUI

@Observable
final class PullListPDFViewModelV2 {

    // MARK: - State

    private(set) var pdfDocument: PDFDocument? = nil
    private(set) var pdfData: Data? = nil
    private(set) var errorMessage: String? = nil

    let info: PDFListInfo

    // MARK: - Dependencies

    private let roomIds: [String]
    private let getRooms: ([String]) async throws -> [RoomV2]
    private let itemRepo: ItemRepository
    private let essentialsRepo: EssentialsRepository

    // MARK: - Init

    init(list: PullListV2, roomRepo: RoomRepository<PullListV2>, itemRepo: ItemRepository, essentialsRepo: EssentialsRepository) {
        self.info = PDFListInfo(list)
        self.roomIds = list.roomIds
        self.getRooms = { try await roomRepo.get(ids: $0) }
        self.itemRepo = itemRepo
        self.essentialsRepo = essentialsRepo
    }

    init(list: InstalledListV2, roomRepo: RoomRepository<InstalledListV2>, itemRepo: ItemRepository, essentialsRepo: EssentialsRepository) {
        self.info = PDFListInfo(list)
        self.roomIds = list.roomIds
        self.getRooms = { try await roomRepo.get(ids: $0) }
        self.itemRepo = itemRepo
        self.essentialsRepo = essentialsRepo
    }

    // MARK: - Generation

    @MainActor
    func generatePDF() async {
        errorMessage = nil

        do {
            let rooms = try await fetchRooms()
            let itemsById = try await fetchItems(for: rooms)
            let essentialsNames = try await fetchEssentialsNames(for: itemsById)
            let images = await preloadImages(for: itemsById)

            let content = PullListPDFContent(
                pullList: info,
                rooms: rooms,
                itemsById: itemsById,
                essentialsNamesById: essentialsNames,
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
}

// MARK: - Fetching

private extension PullListPDFViewModelV2 {

    func fetchRooms() async throws -> [RoomV2] {
        guard !roomIds.isEmpty else { return [] }
        return try await getRooms(roomIds)
            .sorted { $0.displayName < $1.displayName }
    }

    /// One fetch for the whole list rather than one per room, so items shared
    /// across rooms are only read once.
    func fetchItems(for rooms: [RoomV2]) async throws -> [String: ItemV2] {
        let ids = Array(Set(rooms.flatMap(\.itemIds)))
        let items = try await itemRepo.get(ids: ids)

        var byId: [String: ItemV2] = [:]
        for item in items { byId[item.id] = item }
        return byId
    }

    /// One fetch for every distinct essentials group the items belong to.
    func fetchEssentialsNames(for itemsById: [String: ItemV2]) async throws -> [String: String] {
        let ids = Array(Set(itemsById.values.compactMap(\.essentialGroupId)))
        guard !ids.isEmpty else { return [:] }

        let groups = try await essentialsRepo.get(ids: ids)
        return Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0.baseName) })
    }

    func preloadImages(for itemsById: [String: ItemV2]) async -> [String: UIImage] {
        await withTaskGroup(of: (String, UIImage)?.self) { group in
            for (itemId, item) in itemsById {
                let image = item.primaryImage
                group.addTask {
                    guard let uiImage = await image.loadUIImage() else { return nil }
                    return (itemId, uiImage)
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
