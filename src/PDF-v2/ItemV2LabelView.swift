//
//  ItemV2LabelView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/5/26.
//

import SwiftUI
import PDFKit

struct ItemV2LabelView: View {
    let item: ItemV2
    let qrCode: UIImage?
    let image: RDImage
    
    @State private var pdfDocument: PDFDocument? = nil
    @State private var isGeneratingPDF: Bool = false
    @State private var pdfData: Data? = nil
    
    init(item: ItemV2) {
        self.item = item
        self.qrCode = item.id.generateQRCode()
        image = item.primaryImage
    }
    
        // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            TopBar()
            
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
                                "NAME:\(item.name)-ID:\(item.id)-Label.pdf",
                                image: Image(systemName: SFSymbols.docFill)
                            ),
                            label: {
                                HStack(spacing: 8) {
                                    Image(systemName: SFSymbols.squareAndArrowUp)
                                        .font(.system(size: 16))
                                        .fontWeight(.bold)
                                    
                                    Text("Share / Export Label")
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
            
            Spacer()
        }
        .task {
            await generatePDF()
        }
        .frameTop()
        .frameHorizontalPadding()
        .toolbar(.hidden)
    }
    
        // MARK: Top Bar
    
    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(leadingView: {
            BackButton()
        }, header: {
            Text("QR Code")
        }, trailingView: {
            Spacer().frame(width: 32)
        })
    }
    
    // MARK: PDF Generator
    
    @MainActor
    private func generatePDF() async {
        isGeneratingPDF = true
        
        // Preload item image if available
        var itemImage: UIImage? = nil
        if let imageURL = image.imageURL {
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                itemImage = UIImage(data: data)
            } catch {
                print("Failed to preload image: \(error)")
            }
        }
        
        let highResQRCode = item.id.generateQRCode(scale: 3.0)
        
        let pdfView = ItemV2LabelGeneratedPDFView(
            item: item,
            qrCodeImage: highResQRCode,
            itemImage: itemImage
        )
        
        let renderer = ImageRenderer(content: pdfView)
        renderer.proposedSize = .init(width: 690, height: 1000)
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".pdf")
        
        renderer.render { size, context in
                // Use the actual rendered size for the PDF page
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
