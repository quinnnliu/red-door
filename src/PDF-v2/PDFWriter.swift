//
//  PDFWriter.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/30/26.
//

import CoreGraphics
import Foundation
import SwiftUI

enum PDFWriterError: Error {
    case contextUnavailable
    case emptyDocument
}

/// Renders a list of page-sized views into a single PDF. Knows nothing about
/// what it is drawing — see `PDFPaginator` for the layer that decides which
/// content lands on which page.
@MainActor
enum PDFWriter {

    /// PDF points are 1/72", so these are literal inches: 8.5 x 11.
    static let letter = CGSize(width: 612, height: 792)

    /// One page per view, in order. Writes to memory rather than a temp file so
    /// a failure surfaces as a thrown error instead of an unreadable file.
    static func data(pages: [AnyView], pageSize: CGSize = letter) throws -> Data {
        guard !pages.isEmpty else { throw PDFWriterError.emptyDocument }

        let output = NSMutableData()
        var box = CGRect(origin: .zero, size: pageSize)

        guard let consumer = CGDataConsumer(data: output),
              let pdf = CGContext(consumer: consumer, mediaBox: &box, nil)
        else { throw PDFWriterError.contextUnavailable }

        for page in pages {
            let renderer = ImageRenderer(
                content: page.frame(width: pageSize.width, height: pageSize.height, alignment: .topLeading)
            )
            renderer.proposedSize = .init(width: pageSize.width, height: pageSize.height)

            pdf.beginPDFPage(nil)
            renderer.render { _, draw in draw(pdf) }
            pdf.endPDFPage()
        }

        pdf.closePDF()
        return output as Data
    }
}
