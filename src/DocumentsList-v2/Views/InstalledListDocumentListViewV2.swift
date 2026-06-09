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

                Menu {
//                    NavigationLink(destination: CreateInstalledListViewV2()) {
//                        Text("From Scratch")
//                        Image(systemName: SFSymbols.checklist)
//                    }
//                    Button {
//                        showFromInstalledCover = true
//                    } label: {
//                        Text("From Installed List")
//                        Image(systemName: SFSymbols.documentOnDocument)
//                    }
                } label: {
                    RDButton(variant: .outline, size: .icon, leadingIcon: "plus", iconBold: true, fullWidth: false, action: { })
                }
            }
            .foregroundColor(.red)
        }
    }

    // MARK: InstalledList List

    @ViewBuilder
    private var InstalledListListSection: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.documents, id: \.id) { list in
//                    NavigationLink(value: NavigationDestination.InstalledListDetailView(list)) {
//                        InstalledListV2ListItem(list: list)
//                    }
//                    .buttonStyle(PlainButtonStyle())
                    
                    Text(list.displayName)
                }

                LoadMoreButton()
            }
            .padding(8)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private func LoadMoreButton() -> some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else if viewModel.hasMore {
            RDButton(
                variant: .outline,
                label: "Load More",
                fullWidth: true
            ) {
                Task { await viewModel.loadMore() }
            }
            .padding(.vertical, 4)
        }
    }
}

private extension InstalledListDocumentListViewV2 {
    func handleAction(_ action: Any?) {
        guard let action else { return }

        switch action {
        case let searchAction as SearchBarAction:
            switch searchAction {
            case .search(let text):
                Task { await viewModel.search(text: text) }
            case .cancel:
                Task { await viewModel.refresh() }
            }
        default:
            print("ERROR: Untracked action")
        }
    }
}
