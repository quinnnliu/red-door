//
//  UninstallRecordSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/28/26.
//

import SwiftUI

struct UninstallRecordSheet: View {
    @State private var viewModel: UninstallRecordSheetViewModel

    init(viewModel: UninstallRecordSheetViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 16) {
            DragIndicator()

            Header

            Content

            Spacer(minLength: 0)
        }
        .toolbar(.hidden)
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .task {
            await viewModel.load()
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("Ok", role: .cancel) {}
        }
    }
}

private extension UninstallRecordSheet {

    // MARK: Header

    var Header: some View {
        VStack(spacing: 4) {
            (
                Text("Uninstalled: ")
                    .foregroundStyle(.red)
                    .bold()
                +
                Text(viewModel.installedList.displayName)
            )
            .font(.headline)

            if let date = viewModel.uninstalledDateLabel {
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Content

    @ViewBuilder
    var Content: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(.red)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if viewModel.recordMissing {
            EmptyState
        } else {
            RecordList
        }
    }

    var EmptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: SFSymbols.infoCircleFill)
                .foregroundStyle(.secondary)

            Text("No uninstall details were recorded for this list.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    var RecordList: some View {
        ScrollView {
            LazyVStack(spacing: 8, pinnedViews: .sectionHeaders) {
                if viewModel.essentialsGroupState != nil && viewModel.essentialsDestination == nil {
                    Section {
                        EssentialsGroupRow
                    } header: {
                        UninstallSectionHeader(title: "Essentials")
                    }
                }

                if !viewModel.storageGroupsIncludingEssentials.isEmpty {
                    StorageSection
                }

                if viewModel.showCopySection {
                    CopySection
                }

                if viewModel.showExistingSection {
                    ExistingListSection
                }
            }
        }
    }

    // MARK: Destination sections
    var StorageSection: some View {
        Section {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(viewModel.storageGroupsIncludingEssentials, id: \.storageLocationId) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        if viewModel.storageGroupsIncludingEssentials.count > 1 {
                            Text(group.storageLocation)
                                .font(.subheadline)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        UninstallAssignedItemsList(entries: group.items)

                        if viewModel.essentialsAssigned(to: .storage, locationId: group.storageLocationId) {
                            EssentialsGroupRow
                        }
                    }
                }
            }
        } header: {
            UninstallSectionHeader(title: "Storage", count: viewModel.storageItemCount)
        }
    }

    var CopySection: some View {
        Section {
            VStack(spacing: 8) {
                UninstallAssignedItemsList(entries: viewModel.copyItems)

                if viewModel.essentialsAssigned(to: .copy) {
                    EssentialsGroupRow
                }
            }
        } header: {
            UninstallSectionHeader(
                title: viewModel.copySectionTitle,
                subtitle: viewModel.copySectionSubtitle,
                count: viewModel.copyItems.count
            )
        }
    }

    var ExistingListSection: some View {
        Section {
            VStack(spacing: 8) {
                UninstallAssignedItemsList(entries: viewModel.existingListItems)

                if viewModel.essentialsAssigned(to: .existingList) {
                    EssentialsGroupRow
                }
            }
        } header: {
            UninstallSectionHeader(
                title: viewModel.existingSectionTitle,
                count: viewModel.existingListItems.count
            )
        }
    }

    // MARK: EssentialsGroupRow

    @ViewBuilder
    var EssentialsGroupRow: some View {
        if let group = viewModel.essentialsGroupState {
            UninstallEssentialsSummaryView(
                group: group,
                items: viewModel.essentialsItems,
                accessories: viewModel.essentialsAccessories,
                destinationLabel: viewModel.essentialsDestinationLabel?.title,
                destinationSubtitle: viewModel.essentialsDestinationLabel?.subtitle
            )
        }
    }
}
