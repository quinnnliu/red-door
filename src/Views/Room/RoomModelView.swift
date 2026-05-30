//
//  RoomModelView.swift
//  RedDoor
//
//  Created by Quinn Liu on 2/23/25.
//

import CachedAsyncImage
import SwiftUI

struct RoomModelView: View {
    // MARK: Environment variables

    @Environment(\.dismiss) private var dismiss
    @State private var modelViewModel: ModelViewModel
    @Binding private var roomViewModel: RoomViewModel

    // MARK: State Variables

    @State private var showingDeleteAlert = false

    // MARK: RD Image Refactor

    @State private var selectedRDImage: RDImage? = nil
    @State private var isImageSelected: Bool = false

    // MARK: Initializer

    init(model: Model, roomViewModel: Binding<RoomViewModel>) {
        modelViewModel = ModelViewModel(model: model)
        _roomViewModel = roomViewModel
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 12) {
            DragIndicator()
            
            TopBar()

            ModelImages(model: $modelViewModel.selectedModel, selectedRDImage: $selectedRDImage, isImageSelected: $isImageSelected, isEditing: .constant(false))

            ModelInformationView(model: modelViewModel.selectedModel)

            ModelItemListView()
        }
        .frameTop()
        .frameHorizontalPadding()
        .toolbar(.hidden)
        .task {
            await loadItems()
        }
        .overlay(
            ModelRDImageOverlay(selectedRDImage: selectedRDImage, isImageSelected: $isImageSelected)
        )
    }

    // MARK: Top Bar
    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(
            leadingView: {
                BackButton()
            },
            header: {
                ModelNameView()
            },
            trailingView: {
                Spacer().frame(32)
            }
        )
    }

    // MARK: - Model Name View

    @ViewBuilder 
    private func ModelNameView() -> some View {
        HStack {
            Text("Name:")
                .font(.headline)
            Text(modelViewModel.selectedModel.name)
        }
    }

    // MARK: Model Item List View

    @ViewBuilder
    private func ModelItemListView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 0) {
                Text("Item Count: ")
                    .foregroundColor(.red)
                    .bold()
                
                Text("\(modelViewModel.selectedModel.itemIds.count)")
                    .bold()
            }

            if !modelViewModel.items.isEmpty {
                let columns = [
                    GridItem(.flexible(), spacing: 4),
                    GridItem(.flexible(), spacing: 4)
                ]

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(modelViewModel.items.enumerated()), id: \.element.id) { index, item in
                            if item.isAvailable {
                                NavigationLink(destination: RoomItemView(item: item, model: modelViewModel.selectedModel, roomViewModel: $roomViewModel)) {
                                    ModelItemListItem(item: item, model: modelViewModel.selectedModel, index: index)
                                }
                            } else {
                                ModelItemListItem(item: item, model: modelViewModel.selectedModel, index: index)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: loadItems()

    private func loadItems() async {
        do {
            modelViewModel.items = try await modelViewModel.getModelItems()
        } catch {
            print("Error loading model items: \(error.localizedDescription)")
        }
    }
}
