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
    @State private var showInformation: Bool = false
    
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
                    .padding(.horizontal, 16)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ItemImageView(
                            image: viewModel.item.primaryImage,
                            selectedImage: $viewModel.selectedRDImage,
                            isImageSelected: $viewModel.isImageSelected
                        )
                        
                        VStack(spacing: 12) {
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    showInformation.toggle()
                                }
                            } label: {
                                HStack(spacing: 0) {
                                    Text("Information")
                                        .foregroundColor(.white)
                                        .bold()
                                    
                                    Spacer()
                                    
                                    Image(systemName: showInformation ? SFSymbols.chevronUp : SFSymbols.chevronDown)
                                        .foregroundColor(.white)
                                }
                                .padding(8)
                                .background(.red)
                                .cornerRadius(6)
                            }
                            
                            if showInformation {
                                ItemDetailSection(item: viewModel.item)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            RDButton(
                                variant: .red,
                                leadingIcon: SFSymbols.plus,
                                iconBold: true,
                                label: "Add to \(viewModel.room.displayName)",
                                fullWidth: true
                            ) {
                                Task {
                                    await viewModel.addItemToRoom()
                                    dismiss()
                                }
                            }.frame(alignment: .bottom)
                        }
                    }
                    .padding(.top, 4)
                    .frameHorizontalPadding()
                }
                
                
            }
            .frameTop()
            .toolbar(.hidden)
            .overlay(
                ModelRDImageOverlay(
                    selectedRDImage: viewModel.selectedRDImage,
                    isImageSelected: $viewModel.isImageSelected
                )
                .animation(.easeInOut(duration: 0.3), value: viewModel.isImageSelected)
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
