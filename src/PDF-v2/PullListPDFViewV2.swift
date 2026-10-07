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
    @State private var viewModel: PullListPDFViewModelV2

    init(viewModel: PullListPDFViewModelV2) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BackButton()

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
        }
        .task {
            await viewModel.generatePDF()
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
                "(\(viewModel.info.kindTitle)) \(viewModel.info.address.formattedAddress).pdf",
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
