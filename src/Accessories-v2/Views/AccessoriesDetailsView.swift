//
//  AccessoriesDetailsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/20/26.
//

import SwiftUI

struct AccessoriesDetailsView: View {
    @State private var accessories: Accessories
    @State private var showEditSheet: Bool = false

    init(accessories: Accessories) {
        self._accessories = State(initialValue: accessories)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                TopBar
                NicknameEntry
            }
            .frameHorizontalPadding()

            ImageSection

            DescriptionSection
                .frameHorizontalPadding()

            Spacer()
        }
        .toolbar(.hidden)
        .frameTop()
        .sheet(isPresented: $showEditSheet) {
            AccessoriesViewFactory().makeEditAccessoriesSheet(accessories: accessories) { updated in
                accessories = updated
            }
        }
    }
}

// MARK: - Top Bar

private extension AccessoriesDetailsView {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton()
            },
            header: {
                VStack(alignment: .center, spacing: 2) {
                    Text(accessories.baseName)
                        .font(.headline)
                        .bold()
                }
            },
            trailingView: {
                RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.pencil) {
                    showEditSheet = true
                }
                .clipShape(Circle())
            }
        )
    }
}

// MARK: - Nickname Entry

private extension AccessoriesDetailsView {
    var NicknameEntry: some View {
        Group {
            if let nickname = accessories.nickname, !nickname.isEmpty {
                Text(nickname)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Image Section

private extension AccessoriesDetailsView {
    var ImageSection: some View {
        PrimaryImageView(image: accessories.primaryImage)
    }
}

// MARK: - Description Section

private extension AccessoriesDetailsView {
    var DescriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .foregroundStyle(.red)

            Text(accessories.description.isEmpty ? "No description" : accessories.description)
                .foregroundStyle(accessories.description.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                .padding(10)
                .background(Color(.systemGray5))
                .cornerRadius(8)
        }
    }
}
