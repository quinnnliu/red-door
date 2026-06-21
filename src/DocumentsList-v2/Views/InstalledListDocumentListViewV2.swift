//
//  InstalledListDocumentListViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/8/26.
//

import SwiftUI

struct InstalledListDocumentListViewV2: View {
    @State private var viewModel: DocumentListViewModelV2<InstalledListV2> = DocumentListViewModelV2<InstalledListV2>()
    @Binding var path: NavigationPath

    @State private var searchFocused: Bool = false
    @State private var showFromInstalledCover: Bool = false

    init(
        path: Binding<NavigationPath>
    ) {
        self._path = path
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 12) {
                if searchFocused {
                    SearchBarV2(isActive: $searchFocused, action: handleAction(_:))
                } else {
                    TopBar
                }

                InstalledListListSection
            }
            .frameTop()
            .frameHorizontalPadding()
            .task {
                await viewModel.refresh()
            }
            .fullScreenCover(isPresented: $showFromInstalledCover) {
                // TODO: add from installed list functionality
            }
            .rootNavigationDestinationsV2(path: $path)
        }
    }
}

extension InstalledListDocumentListViewV2 {
    // MARK: Top Bar

    @ViewBuilder
    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                Text("Installed Lists")
                    .font(.system(.title2, design: .default))
                    .bold()
                    .foregroundStyle(.red)
            },
            header: {
                EmptyView()
            },
            trailingView: {
                TrailingIconGroup
            }
        ).tint(.red)
    }

    // MARK: Trailing Icons

    private var TrailingIconGroup: some View {
        HStack(spacing: 8) {
            Group {
                RDButton(variant: .outline, size: .icon, leadingIcon: "magnifyingglass", iconBold: true, fullWidth: false) {
                    searchFocused = true
                }
            }
            .foregroundColor(.red)
        }
    }

    // MARK: InstalledList List

    private var InstalledListListSection: some View {
        DocumentListSection(
            viewModel: viewModel,
            noMoreLabel: "No More Installed Lists",
            destination: { .installedListDetailView($0) },
            rowContent: { InstalledListV2ListItem(list: $0) }
        )
    }
}

private extension InstalledListDocumentListViewV2 {
    func handleAction(_ action: Any?) {
        guard let action else { return }

        switch action {
        case let searchAction as SearchBarAction:
            Task { await viewModel.handleSearchAction(searchAction) }
        default:
            print("ERROR: Untracked action")
        }
    }
}
