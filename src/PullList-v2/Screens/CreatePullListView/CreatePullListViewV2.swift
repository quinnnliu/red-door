//
//  CreatePullListViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import SwiftUI

struct CreatePullListViewV2: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: CreatePullListViewModelV2 = .init()
    
    @State private var showAddressSheet: Bool = false
    @State private var selectedAddressMode: String = "Search"
    @State private var address: String = ""
    
    @State private var showCreateRoomSheet: Bool = false
    private var rooms: [Room]?
    
    
    
    // MARK: Body
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                TopBar

                PrimaryImageEditor(image: viewModel.pullListState.image) { result in
                    handleImageAction(result)
                }

                DatePicker(
                    selection: $viewModel.pullListState.installDate,
                    displayedComponents: [.date]
                ) {
                    Text("Install Date:")
                        .foregroundColor(.secondary)
                        .bold()
                }
                
                DatePicker(
                    selection: $viewModel.pullListState.uninstallDate,
                    displayedComponents: [.date]
                ) {
                    Text("Uninstall Date:")
                        .foregroundColor(.red)
                        .bold()
                }
                
                HStack {
                    Text("Client:")
                    TextField("", text: $viewModel.pullListState.clientId)
                        .padding(6)
                        .background(Color(.systemGray5))
                        .cornerRadius(Constants.CornerRadius.medium)
                }
                
                HStack {
                    Text("Square Feet:")
                    TextField("Optional", text: Binding(
                        get: { viewModel.pullListState.squareFootage ?? "" },
                        set: { viewModel.pullListState.squareFootage = $0.isEmpty ? nil : $0 }
                    ))
                    .padding(6)
                    .background(Color(.systemGray5))
                    .cornerRadius(Constants.CornerRadius.medium)
                }
                
                HStack(spacing: 0) {
                    Text("Rooms:")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    SmallCTA(type: .red, leadingIcon: "plus", text: "Add Room") {
                        showCreateRoomSheet = true
                    }
                }
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.rooms, id: \.self) { room in
                            EmptyRoomListItem(room.displayName, squareFootage: room.squareFootage)
                        }
                    }
                }
                
                RDButton(
                    variant: .red,
                    size: .default,
                    leadingIcon: SFSymbols.plus,
                    label: "Create Pull List",
                    fullWidth: true
                ) {
                    Task {
                        await viewModel.createPullList()
                        dismiss()
                    }
                }
                .disabled(viewModel.createButtonDisabled)
                .padding(.bottom, 16)
                
            }
            .toolbar(.hidden)
            .frameHorizontalPadding()
            .alert(viewModel.alertText, isPresented: $viewModel.showAlert) {
                Button("Ok", role: .cancel) {}
            }
            .sheet(isPresented: $showCreateRoomSheet) {
                EditRoomV2Sheet { roomName, squareFootage in
                    viewModel.createEmptyRoom(roomName, squareFootage: squareFootage)
                }
            }
            .sheet(isPresented: $showAddressSheet) {
                AddressSheet(selectedAddress: $viewModel.pullListState.address, addressId: $viewModel.pullListState.addressId)
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Creating Pull List...")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
            }
        }
    }
    
    // MARK: TopBar
    
    @ViewBuilder
    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton()
            }, header: {
                RDButton(
                    variant: .outline,
                    size: .default,
                    leadingIcon: SFSymbols.mapPinAndEllipse,
                    label: viewModel.pullListState.address.isInitialized() ? viewModel.pullListState.address.getStreetAddress() ?? "" : "Enter Address") {
                    showAddressSheet = true
                }
            }, trailingView: {
                Spacer().frame(width: 32)
            }
        )
    }
    
    // MARK: Create Empty Room Sheet
    
    @FocusState var keyboardFocused: Bool
    @State private var newRoomName: String = ""
    @State private var existingRoomAlert: Bool = false
    @ViewBuilder
    private var CreateEmptyRoomSheet: some View {
        VStack(spacing: 16) {
            TextField("Room Name", text: $newRoomName)
                .focused($keyboardFocused)
                .submitLabel(.done)
            
            HStack(spacing: 0) {
                Button {
                    showCreateRoomSheet = false
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                Button {
                    viewModel.createEmptyRoom(newRoomName)
                } label: {
                    Text("Add Room")
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }
        }
        .alert("Room with that name already exists.", isPresented: $existingRoomAlert) {
            Button("Ok", role: .cancel) {}
        }
        .frameTop()
        .padding(24)
        .presentationDetents([.fraction(0.125)])
    }
    
    // MARK: Empty Room List Item
    
    @ViewBuilder
    private func EmptyRoomListItem(_ roomName: String, squareFootage: String?) -> some View {
        VStack(spacing: 4) {
            Text(roomName)
                .foregroundStyle(Color(.label))
            if let squareFootage {
                Text("\(squareFootage) sq ft")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

extension CreatePullListViewV2 {
    func handleImageAction(_ actionArgument: Any?) {
        guard let action = actionArgument as? ImageEditorAction else { return }
        switch action {
        case .newImage(let image):
            viewModel.pullListState.image = image
        case .deleteImage:
            viewModel.pullListState.image = nil
        }
    }
}

#Preview {
    CreatePullListViewV2()
}
