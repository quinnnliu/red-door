//
//  PullListDocumentListViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import SwiftUI

struct PullListDocumentListViewV2: View {
    @State private var viewModel: DocumentListViewModelV2<PullListV2> = DocumentListViewModelV2<PullListV2>()
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

                PullListListSection
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

extension PullListDocumentListViewV2 {
    // MARK: Top Bar

    @ViewBuilder
    private var TopBar: some View {
        TopAppBar(
            leadingView: {
                Text("Pull Lists")
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

                Menu {
                    NavigationLink(destination: CreatePullListViewV2()) {
                        Text("From Scratch")
                        Image(systemName: SFSymbols.checklist)
                    }
                    Button {
                        showFromInstalledCover = true
                    } label: {
                        Text("From Installed List")
                        Image(systemName: SFSymbols.documentOnDocument)
                    }
                } label: {
                    RDButton(variant: .outline, size: .icon, leadingIcon: "plus", iconBold: true, fullWidth: false, action: { })
                }
            }
            .foregroundColor(.red)
        }
    }

    // MARK: PullList List

    private var PullListListSection: some View {
        DocumentListSection(
            viewModel: viewModel,
            noMoreLabel: "No More Pull Lists",
            destination: { .pullListDetailView($0) },
            rowContent: { PullListV2ListItem(list: $0) }
        )
    }
}

private extension PullListDocumentListViewV2 {
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

#Preview {
    PullListDocumentListViewV2(path: .constant(.init()))
}
