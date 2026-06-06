//
//  PDFViewWrapper.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/22/25.
//

import Foundation
import PDFKit
import SwiftUI

// MARK: - PDFKit View Wrapper

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context _: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.layer.cornerRadius = 12
        pdfView.layer.masksToBounds = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context _: Context) {
        uiView.document = document
    }
}

// MARK: - PDF File Wrapper for ShareLink

struct PDFFile: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { pdf in
            pdf.data
        }
    }
}

