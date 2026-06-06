//
//  PDFPreviewUtils.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/6/25.
//

import Foundation
import PDFKit
import SwiftUI

struct PullListPDFView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var pdfDocument: PDFDocument? = nil
    @State private var isGeneratingPDF: Bool = false
    @State private var pdfData: Data? = nil

    var pullList: RDList
    var rooms: [Room]

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BackButton()

            VStack(alignment: .center, spacing: 0) {
                if pdfDocument == nil {
                    Spacer()

                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Generating PDF")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

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

                    // iOS 17+ ShareLink
                    if #available(iOS 17, *), let pdfData {
                        ShareLink(
                            item: PDFFile(data: pdfData),
                            preview: SharePreview(
                                "PullList.pdf",
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

    // MARK: PDF Generator

    @MainActor
    private func generatePDF() async {
        isGeneratingPDF = true

        // Ensure all RoomViewModels are ready
        var roomViewModels: [RoomViewModel] = []

        for room in rooms {
            let roomVM = RoomViewModel(room: room)
            await roomVM.getRoomItems()
            await roomVM.getRoomModels()
            roomViewModels.append(roomVM)
        }

        let preloadedImages: [String: UIImage] = await preloadImages(for: roomViewModels)

        let pdfView = PLGeneratedPDFView(
            pullList: pullList,
            roomViewModels: roomViewModels,
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
    }
}

// MARK: - Preload Images

func preloadImages(for rooms: [RoomViewModel]) async -> [String: UIImage] {
    var result: [String: UIImage] = [:]

    for roomVM in rooms {
        for item in roomVM.items {
            if let itemImage = item.image {
                if let imageURL = itemImage.imageURL {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: imageURL)
                        if let image = UIImage(data: data) {
                            result[item.id] = image
                        }
                    } catch {
                        print("Failed to preload image for item \(item.id): \(error)")
                    }
                }
            } else if let modelImageURL = roomVM.modelsById[item.modelId]?.primaryImage.imageURL {
                do {
                    let (data, _) = try await URLSession.shared.data(from: modelImageURL)
                    if let image = UIImage(data: data) {
                        result[item.id] = image
                    }
                } catch {
                    print("Failed to preload image for item \(item.id): \(error)")
                }
            }
        }
    }
    return result
}

