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
    @State private var showFilterSheet: Bool = false
    @State private var showCreatePullListSheet: Bool = false

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
            .fullScreenCover(isPresented: $showCreatePullListSheet) {
                CreatePullListViewV2()
            }
            .sheet(isPresented: $showFilterSheet) {
                PullListV2DocumentFilterSheet(
                    initialFilters: viewModel.activeFilters,
                    action: handleAction(_:)
                )
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
                HStack(spacing: 8) {
                    Text("Pull Lists")
                        .font(.system(.title2, design: .default))
                        .bold()
                        .foregroundStyle(.red)
                    
                    FilterButton(viewModel.activeFiltersApplied)
                }
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
                RDButton(variant: .outline, size: .icon, leadingIcon: "magnifyingglass", fullWidth: false) {
                    withAnimation(Constants.Animation.snappy) {
                        searchFocused = true
                    }
                }

                Menu {
                    Button {
                        showCreatePullListSheet = true
                    } label: {
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
                    RDButton(variant: .outline, size: .icon, leadingIcon: "plus", fullWidth: false, action: { })
                }
            }
            .foregroundColor(.red)
        }
    }

    // MARK: FilterButton

    private func FilterButton(_ filtersActive: Bool = false) -> some View {
        RDButton(
            variant: filtersActive ? .red : .secondary,
            size: .icon,
            leadingIcon: SFSymbols.sliderHorizontal3
        ) {
            showFilterSheet = true
        }
        .clipShape(.circle)
    }

    // MARK: PullList List

    private var PullListListSection: some View {
        DocumentListSection(
            viewModel: viewModel,
            noMoreLabel: "No More Pull Lists",
            action: handleAction(_:),
            rowContent: { pullList in
                PullListListItemV2(list: pullList, action: handleAction(_:))
            }
        )
    }
}

private extension PullListDocumentListViewV2 {
    func handleAction(_ action: Any?) {
        guard let action else { return }

        switch action {
        case let searchAction as SearchBarAction:
            Task { await viewModel.handleSearchAction(searchAction) }
        case let filterAction as DocumentFilterSheetAction:
            Task {
                switch filterAction {
                case .applyFilters(let filters): await viewModel.setFilters(filters)
                }
            }
        case let sectionAction as DocumentListSectionAction:
            switch sectionAction {
            case .loadMore:
                Task { await viewModel.loadMore() }
            }
        case let listAction as PullListListItemAction:
            switch listAction {
            case .documentList(let list):
                path.append(NavigationDestination.pullListDetailView(list))
            default:
                return
            }
        default:
            print("ERROR: Untracked action")
        }
    }
}

#Preview {
    PullListDocumentListViewV2(path: .constant(.init()))
}
