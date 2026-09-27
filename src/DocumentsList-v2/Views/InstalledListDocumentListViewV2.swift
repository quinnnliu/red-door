//
//  InstalledListDocumentListViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/8/26.
//

import SwiftUI

struct InstalledListDocumentListViewV2: View {
    @State private var viewModel: DocumentListViewModelV2<InstalledListV2> = DocumentListViewModelV2<InstalledListV2>(defaultFilters: ["uninstalled": true])
    @State private var installedListRepository = InstalledListRepository()
    @Binding var path: NavigationPath

    @State private var installedLists: [InstalledListV2] = []
    @State private var isLoadingInstalled: Bool = false
    @State private var showInstalledSection: Bool = true

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

                InstalledSection
                InstalledListListSection
            }
            .frameTop()
            .frameHorizontalPadding()
            .task {
                async let mainRefresh: () = viewModel.refresh()
                async let installedLoad: () = loadInstalledLists()
                _ = await (mainRefresh, installedLoad)
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
                RDButton(variant: .outline, size: .icon, leadingIcon: "magnifyingglass", fullWidth: false) {
                    withAnimation(Constants.Animation.snappy) {
                        searchFocused = true
                    }
                }
            }
            .foregroundColor(.red)
        }
    }

    // MARK: Installed Section

    @ViewBuilder
    private var InstalledSection: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(Constants.Animation.snappy) {
                    showInstalledSection.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Installed")
                        .font(.headline)
                        .foregroundColor(.red)

                    Image(systemName: SFSymbols.checkmarkCircleFill)
                        .font(.headline)
                        .foregroundColor(.red)

                    Spacer()

                    Text("(\(installedLists.count))")
                        .foregroundColor(.secondary)

                    Image(systemName: showInstalledSection ? SFSymbols.chevronUp : SFSymbols.chevronDown)
                        .bold()
                        .foregroundColor(.red)
                }
            }
            .disabled(installedLists.isEmpty)

            if !installedLists.isEmpty && showInstalledSection {
                if isLoadingInstalled {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(installedLists) { list in
                            InstalledListV2ListItem(list: list, action: handleAction(_:))
                        }
                    }
                }
            }
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.red, lineWidth: 4)
        )
    }

    // MARK: InstalledList List

    private var InstalledListListSection: some View {
        DocumentListSection(
            viewModel: viewModel,
            noMoreLabel: "No More Uninstalled Lists",
            action: handleAction(_:),
            rowContent: { list in
                InstalledListV2ListItem(list: list, action: handleAction(_:))
            }
        )
    }
}

private extension InstalledListDocumentListViewV2 {
    func loadInstalledLists() async {
        isLoadingInstalled = true
        defer { isLoadingInstalled = false }
        do {
            installedLists = try await installedListRepository.getAllInstalled()
        } catch {
            print("[InstalledListDocumentListViewV2] failed to load installed lists: \(error)")
        }
    }
}

private extension InstalledListDocumentListViewV2 {
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
                path.append(NavigationDestination.installedListDetailView(list))
            }
        default:
            print("ERROR: Untracked action")
        }
    }
}
