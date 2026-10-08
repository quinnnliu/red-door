//
//  ItemV2PDFViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/06/26.
//

import Foundation
import PDFKit
import SwiftUI

/// Drives the single-item label screen: one page holding the item's QR code,
/// photo and description.
@Observable
final class ItemV2PDFViewModel {

    // MARK: - State

    private(set) var pdfDocument: PDFDocument? = nil
    private(set) var pdfData: Data? = nil
    private(set) var errorMessage: String? = nil

    let item: ItemV2

    // MARK: - Dependencies

    private let storageLocationRepo: StorageLocationRepository
    private let pullListRepo: PullListRepository
    private let installedListRepo: InstalledListRepository

    // MARK: - Init

    init(
        item: ItemV2,
        storageLocationRepo: StorageLocationRepository,
        pullListRepo: PullListRepository,
        installedListRepo: InstalledListRepository
    ) {
        self.item = item
        self.storageLocationRepo = storageLocationRepo
        self.pullListRepo = pullListRepo
        self.installedListRepo = installedListRepo
    }

    // MARK: - Generation

    @MainActor
    func generatePDF() async {
        errorMessage = nil

        // Full resolution: the label prints the photo at 200pt.
        let itemImage = await item.primaryImage.loadUIImage(preferThumbnail: false)

        let pdfView = ItemV2LabelGeneratedPDFView(
            item: item,
            location: await fetchLocation(),
            qrCodeImage: item.id.generateQRCode(scale: 3.0),
            itemImage: itemImage
        )

        let renderer = ImageRenderer(content: pdfView)
        renderer.proposedSize = .init(width: 690, height: 1000)

        do {
            let data = try render(renderer)
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

private extension ItemV2PDFViewModel {

    /// The item's `locationId` points at a storage location or a list depending
    /// on its status. A failed lookup leaves the label without a location
    /// rather than failing the whole PDF.
    func fetchLocation() async -> ItemLocationInfo? {
        let locationId = item.location.locationId
        guard !locationId.isEmpty else { return nil }

        switch item.location.status {
        case .inStorage:
            let locations = try? await ConfigurationService.shared.getAll(using: storageLocationRepo)
            guard let location = locations?.first(where: { $0.id == locationId }) else { return nil }
            return ItemLocationInfo(name: location.displayName, address: location.address.formattedAddress)
        case .inPullList:
            guard let list = try? await pullListRepo.get(id: locationId) else { return nil }
            return ItemLocationInfo(name: list.displayName, address: list.address.formattedAddress)
        case .inInstalledList:
            guard let list = try? await installedListRepo.get(id: locationId) else { return nil }
            return ItemLocationInfo(name: list.displayName, address: list.address.formattedAddress)
        }
    }
}

// MARK: - Rendering

private extension ItemV2PDFViewModel {

    /// One page sized to whatever SwiftUI laid the label out at, so the page
    /// fits its content rather than a fixed paper size. Writes to memory so a
    /// failure surfaces as a thrown error instead of an unreadable file.
    @MainActor
    func render(_ renderer: ImageRenderer<ItemV2LabelGeneratedPDFView>) throws -> Data {
        let output = NSMutableData()
        var didRender = false

        renderer.render { size, draw in
            var box = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: output),
                  let pdf = CGContext(consumer: consumer, mediaBox: &box, nil)
            else { return }

            pdf.beginPDFPage(nil)
            draw(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
            didRender = true
        }

        guard didRender else { throw PDFWriterError.contextUnavailable }
        return output as Data
    }
}
