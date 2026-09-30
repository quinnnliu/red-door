//
//  SelectInstalledListToCopyView.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/29/26.
//

import SwiftUI

/// Step one of copying: choose which installed list to copy.
///
/// Filtered to `uninstalled == true`. A list that is still installed has every
/// item `.inInstalledList`, so copying it could never claim anything.
struct SelectInstalledListToCopyView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = DocumentListViewModelV2<InstalledListV2>(
        defaultFilters: [InstalledListV2.CodingKeys.uninstalled.stringValue: true]
    )
    @State private var path = NavigationPath()
    @State private var searchFocused: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 12) {
                if searchFocused {
                    SearchBarV2(isActive: $searchFocused, action: handleAction(_:))
                } else {
                    TopBar
                }

                DocumentListSection(
                    viewModel: viewModel,
                    noMoreLabel: "No More Uninstalled Lists",
                    action: handleAction(_:),
                    rowContent: { list in
                        InstalledListV2ListItem(list: list, action: handleAction(_:))
                    }
                )
            }
            .frameTop()
            .frameHorizontalPadding()
            .task { await viewModel.refresh() }
            .navigationDestination(for: InstalledListV2.self) { list in
                PullListViewFactory().makeCopyFromInstalledView(installedList: list) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - TopBar

    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton(icon: SFSymbols.xmark) { dismiss() }
            },
            header: {
                Text("Copy From Installed")
                    .bold()
            },
            trailingView: {
                RDButton(
                    variant: .outline,
                    size: .icon,
                    leadingIcon: "magnifyingglass",
                    fullWidth: false
                ) {
                    searchFocused = true
                }
            }
        )
    }
}

// MARK: - Handle Action

private extension SelectInstalledListToCopyView {
    func handleAction(_ action: Any?) {
        guard let action else { return }

        switch action {
        case let searchAction as SearchBarAction:
            Task { await viewModel.handleSearchAction(searchAction) }
        case let sectionAction as DocumentListSectionAction:
            switch sectionAction {
            case .loadMore:
                Task { await viewModel.loadMore() }
            }
        case let listAction as InstalledListListItemAction:
            switch listAction {
            case .navigate(let list):
                path.append(list)
            }
        default:
            break
        }
    }
}
