//
//  PullListDocumentListViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/16/26.
//

import SwiftUI

struct PullListDocumentListViewV2: View {
    @State private var viewModel: DocumentListViewModelV2<RDListV2> = DocumentListViewModelV2<RDListV2>()
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

                PullListList

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
            leadingIcon: {
                Text("Pull Lists")
                    .font(.system(.title2, design: .default))
                    .bold()
                    .foregroundStyle(.red)
            },
            header: {
                EmptyView()
            },
            trailingIcon: {
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

    // MARK: Pull List List

    @ViewBuilder
    private var PullListList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.documents, id: \.id) { list in
                    NavigationLink(value: list) {
                        RDListV2ListItem(list: list)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                LoadMoreButton()
            }
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

private extension PullListDocumentListViewV2 {
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

// MARK: - RDListV2ListItem

struct RDListV2ListItem: View {
    let list: RDListV2

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(list.address.getStreetAddress() ?? "")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                (
                    Text("Install Date: ")
                        .foregroundColor(.red)
                    +
                    Text(list.installDate)
                        .foregroundColor(.secondary)
                )

                (
                    Text("Client ID: ")
                        .foregroundColor(.red)
                    +
                    Text(list.clientId)
                        .foregroundColor(.secondary)
                )
            }
            .font(.caption)

            Spacer()
        }
        .padding(12)
        .background(Color(.systemGray5))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(.systemGray3), lineWidth: 4)
        )
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PullListDocumentListViewV2(path: .constant(.init()))
}
