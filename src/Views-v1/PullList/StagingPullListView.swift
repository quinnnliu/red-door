//
//  StagingPullListView.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/10/25.
//

import SwiftUI

struct StagingPullListView: View {
    @State private var viewModel: PullListViewModel
    @Environment(NavigationCoordinator.self) private var coordinator: NavigationCoordinator

    @State private var showPDFPreview: Bool = false
    @State private var alertMessage: String?
    @State private var showAlert: Bool = false

    init(pullList: RDList) {
        viewModel = PullListViewModel(selectedList: pullList)   
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 12) {
            RDListTopBar(
                streetAddress: $viewModel.selectedList.address, 
                trailingIcon: RefreshButton,
                status: viewModel.selectedList.status
            )

            RDListDetails(list: viewModel.selectedList)

            HStack(spacing: 0) {
                SmallCTA(type: .secondary, leadingIcon: SFSymbols.pencilAndListClipboard, text: "Set as planning") {
                    Task { @MainActor in
                        viewModel.selectedList.status = .planning
                        await viewModel.updateSelectedList()
                        coordinator.resetSelectedPath()
                        try? await Task.sleep(for: .milliseconds(500))
                        coordinator.appendToSelectedPath(viewModel.selectedList)
                    }
                }

                Spacer()

                SmallCTA(type: .secondary, leadingIcon: "richtext.page.fill", text: "Show PDF") {
                    showPDFPreview = true
                }
            }

            RoomList()

            Spacer()

            Footer()
        }
        .frameTop()
        .frameHorizontalPadding()
        .toolbar(.hidden)
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showPDFPreview) {
            PullListPDFView(pullList: viewModel.selectedList, rooms: viewModel.rooms)
        }
        .alert(alertMessage ?? "", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                alertMessage = nil
            }
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
                        StagingRoomListItemView(room: room, parentList: viewModel.selectedList, rooms: viewModel.rooms)
                    }
                }
            }
            .refreshable {
                Task {
                    await viewModel.refreshRDList()
                }
            }
        }
        .task {
            await viewModel.loadRooms()
        }
    }

    // MARK: Footer

    @ViewBuilder
    private func Footer() -> some View {
        RDButton(variant: .red, size: .default, leadingIcon: SFSymbols.truckBoxBadgeClockFill, label: "Create Installed List", fullWidth: true) {
            Task { // TODO: consider wrapping this in some error-handling function
                do {
                    await viewModel.loadRooms() // get updated selections
                    let installedlist = try await viewModel.createInstalledFromPull()
                    await viewModel.deleteRDList()
                    coordinator.resetSelectedPath()
                    try? await Task.sleep(for: .milliseconds(250))
                    coordinator.setSelectedTab(to:.installedList)
                    try? await Task.sleep(for: .milliseconds(250))
                    coordinator.appendToSelectedPath(installedlist)
                } catch let PullListValidationError.itemDoesNotExist(id) {
                    alertMessage = "Item \(id) does not exist."
                    showAlert = true
                } catch let PullListValidationError.itemNotAvailable(id) {
                    alertMessage = "Item \(id) is not available."
                    showAlert = true
                } catch let PullListValidationError.modelDoesNotExist(id) {
                    alertMessage = "Model \(id) does not exist."
                    showAlert = true
                } catch let PullListValidationError.modelAvailableCountInvalid(id) {
                    alertMessage = "Model \(id) has insufficient available items."
                    showAlert = true
                } catch InstalledFromPullError.creationFailed {
                    alertMessage = "Unable to create Installed list."
                    showAlert = true
                } catch {
                    alertMessage = "Unexpected error: \(error.localizedDescription)"
                }
            }            
        }
        .padding(.bottom, 12)
    }

    // MARK: Refresh Button

    @ViewBuilder
    private var RefreshButton: some View {
        RDButton(variant: .red, size: .icon, leadingIcon: "arrow.counterclockwise", iconBold: true, fullWidth: false) {
            Task {
                await viewModel.refreshRDList()
            }
        }
        .clipShape(Circle())
    }
}
