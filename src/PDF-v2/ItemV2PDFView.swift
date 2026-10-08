//
//  ItemV2PDFView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/5/26.
//

import PDFKit
import SwiftUI

struct ItemV2PDFView: View {
    @State private var viewModel: ItemV2PDFViewModel

    init(viewModel: ItemV2PDFViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            TopBar

            VStack(alignment: .center, spacing: 0) {
                if let pdfDocument = viewModel.pdfDocument {
                    PDFKitView(document: pdfDocument)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray, lineWidth: 1)
                        )

                    if let pdfData = viewModel.pdfData {
                        ShareButton(pdfData)
                    }
                } else {
                    Spacer()
                    if let errorMessage = viewModel.errorMessage {
                        ErrorState(errorMessage)
                    } else {
                        LoadingState
                    }
                    Spacer()
                }
            }

            Spacer()
        }
        .task {
            await viewModel.generatePDF()
        }
        .frameTop()
        .frameHorizontalPadding()
        .toolbar(.hidden)
    }
}

// MARK: - Top Bar

private extension ItemV2PDFView {

    var TopBar: some View {
        TopAppBar(leadingView: {
            BackButton()
        }, header: {
            Text("QR Code")
        }, trailingView: {
            Spacer().frame(width: 32)
        })
    }
}

// MARK: - States

private extension ItemV2PDFView {

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
                "NAME:\(viewModel.item.displayName)-ID:\(viewModel.item.id)-Label.pdf",
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
