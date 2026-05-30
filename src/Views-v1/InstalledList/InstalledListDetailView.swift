//
//  InstalledListDetailView.swift
//  RedDoor
//
//  Created by Quinn Liu on 3/27/25.
//

import SwiftUI

struct InstalledListDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator.self) private var coordinator: NavigationCoordinator
    
    @State private var viewModel: InstalledListViewModel

    init(installedList: RDList) {
        viewModel = InstalledListViewModel(selectedList: installedList)
    }

    @State private var showUnstageCover: Bool = false

    // MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RDListTopBar(
                streetAddress: $viewModel.selectedList.address, 
                trailingIcon: InstalledListMenu,
                status: viewModel.selectedList.status
            )

            RDListDetails(list: viewModel.selectedList)

            Text("Rooms:")
                .font(.headline)
                .foregroundColor(.red)
                .bold()

            RoomList()
        }
        .fullScreenCover(isPresented: $showUnstageCover) {
            UnstageInstalledListCover(viewModel: $viewModel)
        }
        .ignoresSafeArea(.keyboard)
        .toolbar(.hidden)
        .frameTop()
        .frameHorizontalPadding()
    }

    // MARK: Room List

    @ViewBuilder 
    private func RoomList() -> some View {
        VStack(spacing: 12) {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.rooms, id: \.self) { room in
                        InstalledRoomListItemView(room: room)
                    }
                }
            }
            .refreshable {
                Task {
                    await viewModel.loadRooms()
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadRooms()
            }
        }
    }

    // MARK: Installed List Menu

    @ViewBuilder 
    private var InstalledListMenu: some View {
        Menu {
            Button("Unstage List", systemImage: "arrow.trianglehead.2.clockwise.rotate.90.page.on.clipboard") {
                showUnstageCover = true
            }

            Button("Create Pull List", systemImage: "pencil.and.list.clipboard") {
                Task {
                    let pullList = try await viewModel.createPullFromInstalled()
                    coordinator.resetSelectedPath()
                    try? await Task.sleep(for: .milliseconds(250))
                    coordinator.setSelectedTab(to:.pullList)
                    try? await Task.sleep(for: .milliseconds(250))
                    coordinator.pullListPath.append(pullList)
                }
            }

        } label: {
            RDButton(variant: .red, size: .icon, leadingIcon: "ellipsis", iconBold: true, fullWidth: false, action: { })
                .clipShape(Circle())
        }
        .tint(.red)
    }
}
