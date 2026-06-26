//
//  EssentialsGroupDetailView.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/25/26.
//

import SwiftUI

struct EssentialsGroupDetailView: View {
    @State private var viewModel: EssentialsGroupDetailViewModel
    @State private var showAddItemsSheet: Bool = false
    @State private var itemToRemove: ItemV2? = nil
    @State private var showRemoveAlert: Bool = false

    init(group: EssentialsGroup) {
        viewModel = EssentialsGroupDetailViewModel(group: group)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            TopBar
                .frameHorizontalPadding()

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        SmallCTA(type: .red, leadingIcon: SFSymbols.plus, text: "Add Items") {
                            showAddItemsSheet = true
                        }
                    }

                    ItemList
                }
                .frameHorizontalPadding()
            }
        }
        .sheet(isPresented: $showAddItemsSheet) {
            AddItemToDocumentSheetV2 { item in
                AddItemDocumentContext.itemToEssentialsGroup(item: item, group: viewModel.groupState)
            }
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK") { }
        }
        .alert("Remove Item", isPresented: $showRemoveAlert) {
            Button("Remove", role: .destructive) {
                if let item = itemToRemove {
                    Task { await viewModel.removeItem(item) }
                }
            }
            Button("Cancel", role: .cancel) {
                itemToRemove = nil
            }
        } message: {
            if let item = itemToRemove {
                Text("Remove \(item.displayName) from \(viewModel.groupState.displayName)?")
            }
        }
        .onAppear {
            viewModel.startListening()
        }
        .toolbar(.hidden)
        .frameTop()
    }
}

// MARK: - Top Bar

private extension EssentialsGroupDetailView {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton()
            },
            header: {
                Text(viewModel.groupState.displayName)
                    .font(.headline)
                    .bold()
            },
            trailingView: {
                EmptyView()
            }
        )
    }
}

// MARK: - Item List

private extension EssentialsGroupDetailView {
    var ItemList: some View {
        LazyVStack(spacing: 8) {
            ForEach(viewModel.items, id: \.id) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.displayName)
                            .font(.body)
                            .bold()
                        Text(item.status.displayTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        itemToRemove = item
                        showRemoveAlert = true
                    } label: {
                        Image(systemName: SFSymbols.xmark)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}
