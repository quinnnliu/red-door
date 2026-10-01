//
//  AddItemToRoomDetailView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import SwiftUI

struct AddItemToRoomDetailView: View {
    // Environment
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: AddItemToRoomDetailViewModel
    
    init(
        item: ItemV2,
        room: RoomV2
    ) {
        viewModel = AddItemToRoomDetailViewModel(item: item, room: room)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                DragIndicator()
                
                TopBar
                    .frameHorizontalPadding()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ItemImageView(
                            image: viewModel.item.primaryImage,
                            selectedImage: $viewModel.selectedRDImage,
                            isImageSelected: $viewModel.isImageSelected
                        )
                        
                        ItemDetailSection(
                            item: viewModel.item,
                            essentialsGroup: viewModel.essentialsGroup
                        )
                        .task { await viewModel.loadEssentialsGroup() }
                    }
                    .padding(.top, 4)
                    .frameHorizontalPadding()
                }
                
                Spacer()
                
                RDButton(
                    variant: .red,
                    leadingIcon: SFSymbols.plus,
                    label: "Add to \(viewModel.room.displayName)",
                    fullWidth: true
                ) {
                    Task {
                        if await viewModel.addItemToRoom() { dismiss() }
                    }
                }
                .frameHorizontalPadding()
            }
            .frameTop()
            .frameBottomPadding()
            .toolbar(.hidden)
            .overlay(
                ModelRDImageOverlay(
                    selectedRDImage: viewModel.selectedRDImage,
                    isImageSelected: $viewModel.isImageSelected
                )
                .animation(Constants.Animation.snappy, value: viewModel.isImageSelected)
            )
            
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Saving Item...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                    .shadow(radius: 10)
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton()
            },
            header: {
                HStack {
                    Text("Name:")
                        .font(.headline)
                    Text(viewModel.item.displayName)
                }
            },
            trailingView: {
                EmptyView()
            }
        )
    }
}
