//
//  PlanningPullListView.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/1/25.
//

import SwiftUI

struct PlanningPullListView: View {
    // MARK: Navigation

    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator.self) private var coordinator: NavigationCoordinator
    @State private var viewModel: PullListViewModel

    // MARK: View State

    @FocusState private var keyboardFocused: Bool
    @State private var showEditSheet: Bool = false
    @State private var showCreateRoom: Bool = false
    @State private var errorMessage: String?
    @State private var showPDF: Bool = false

    @State private var newRoomName: String = ""

    init(pullList: RDList) {
        viewModel = PullListViewModel(selectedList: pullList)
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 12) {
            RDListTopBar(
                streetAddress: $viewModel.selectedList.address, 
                trailingIcon: TopBarMenu,
                status: viewModel.selectedList.status
            )

            RDListDetails(list: viewModel.selectedList)

            HStack(spacing: 0) {
                SmallCTA(type: .secondary, leadingIcon: "arrow.counterclockwise", text: "Refresh") {
                    Task {
                        await viewModel.refreshRDList()
                    }
                }
                
                Spacer()

                SmallCTA(type: .secondary, leadingIcon: "richtext.page.fill", text: "Show PDF") {
                    showPDF = true
                }  
            }

            RoomList()

            Spacer()

            Footer()
        }
        .ignoresSafeArea(.keyboard)
        .toolbar(.hidden)
        .frameTop()
        .frameHorizontalPadding()
        .sheet(isPresented: $showEditSheet) {
            EditPullListDetailsSheet(viewModel: $viewModel)
        }
        .fullScreenCover(isPresented: $showPDF) {
            PullListPDFView(pullList: viewModel.selectedList, rooms: viewModel.rooms)
        }
        .alert("Pull List Not Valid",
            isPresented: .constant(errorMessage != nil),
            actions: {
                Button("Close") { errorMessage = nil }
            },
            message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        )
        .sheet(isPresented: $showCreateRoom) {
            CreateEmptyRoomSheet()
                .onAppear {
                    newRoomName = ""
                    keyboardFocused = true
                }
        }
    }

    // MARK: Top Bar Menu

    @ViewBuilder
    private var TopBarMenu: some View {
        Menu {
            Group {
                Button("Add Room", systemImage: "plus") {
                    showCreateRoom = true
                }

                Button("Edit List Details", systemImage: "pencil") {
                    showEditSheet = true
                }

                Button("Delete Pull List", systemImage: "trash") {
                    Task {
                        await viewModel.deleteRDList()
                        dismiss()
                    }
                }
            }.tint(.red)
        } label: {
            RDButton(variant: .red, size: .icon, leadingIcon: SFSymbols.ellipsis, iconBold: true, fullWidth: false, action: { })
                .clipShape(Circle())
        }
    }

    // MARK: Room List

    @ViewBuilder
    private func RoomList() -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text("Rooms:")
                    .font(.headline)
                    .foregroundColor(.red)

                Spacer()
            }

            ScrollView {
                LazyVStack {
                    ForEach(viewModel.rooms, id: \.self) { room in
                        PreviewRoomListItemView(room: room, parentList: viewModel.selectedList, rooms: viewModel.rooms)
                    }
                }
            }
            .refreshable {
                Task {
                    await viewModel.refreshRDList()
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadRooms()
            }
        }
    }

    // MARK: Footer

    @ViewBuilder
    private func Footer() -> some View {
        RDButton(variant: .red, size: .default, leadingIcon: SFSymbols.truckBoxBadgeClockFill, label: "Begin Install", fullWidth: true) {
            Task { @MainActor in
                viewModel.selectedList.status = .staging
                await viewModel.updateSelectedList()
                coordinator.resetSelectedPath()
                try? await Task.sleep(for: .milliseconds(250))
                coordinator.appendToSelectedPath(viewModel.selectedList)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: Create Empty Room Sheet

    @ViewBuilder
    private func CreateEmptyRoomSheet() -> some View {
        VStack(spacing: 16) {
            TextField("Room Name", text: $newRoomName)
                .focused($keyboardFocused)
                .submitLabel(.done)

            HStack(spacing: 0) {
                Button {
                    showCreateRoom = false
                } label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                }

                Spacer()

                Button {
                    Task {
                        let added = await viewModel.createEmptyRoomExists(roomName: newRoomName)
                        if added { showCreateRoom = false }
                    }
                } label: {
                    Text("Add Room")
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameVerticalPadding()
        .presentationDetents([.fraction(0.125)])
    }
}
