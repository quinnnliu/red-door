//
//  InstalledListDocumentView.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/6/24.
//

import SwiftUI

struct InstalledListDocumentView: View {
    @Binding var path: NavigationPath
    @State private var viewModel = RDListDocumentViewModel(
        documentType: .installed_list,
        primaryStatus: .installed,
        secondaryStatus: .unstaged
    )

    @State private var searchText: String = ""
    @State private var showInstalledLists: Bool = true
    @State private var searchFocused: Bool = false
    @FocusState private var searchTextFocused: Bool
    
    private var isSearching: Bool {
        !searchText.isEmpty
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                if searchFocused {
                    SearchBar()
                } else {
                    TopBar()
                }

                if isSearching {
                    SearchResultsList()
                } else {
                    NormalModeList()
                }
            }
            .task {
                await viewModel.fetchInitialData()
            }
            .frameTop()
            .frameHorizontalPadding()
            .rootNavigationDestinations(path: $path)
        }
    }

    // MARK: Top Bar

    @ViewBuilder private func TopBar() -> some View {
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
                HStack(spacing: 12) {
                    if !searchFocused {
                        RDButton(variant: .outline, size: .icon, leadingIcon: "magnifyingglass", iconBold: true, fullWidth: false) {
                            withAnimation {
                                searchTextFocused = true
                                searchFocused = true
                            }
                        }
                    }

                    RDButton(variant: .outline, size: .icon, leadingIcon: "arrow.counterclockwise", iconBold: true, fullWidth: false) {
                        Task {
                            await viewModel.fetchPrimaryLists()
                            await viewModel.fetchSecondaryLists(initial: true)
                        }
                    }
                }
            }
        ).tint(.red)
    }

    // MARK: Search Bar

    @ViewBuilder 
    private func SearchBar() -> some View {
        SearchBarComponent(
            searchText: $searchText,
            searchFocused: $searchFocused,
            searchTextFocused: $searchTextFocused,
            onSubmit: {
                Task {
                    await viewModel.fetchSearchResults(query: searchText.lowercased())
                }
            },
            onCancel: {
                viewModel.clearSearchResults()
            }
        )
    }

    // MARK: Normal Mode List (installed section + unstaged section)
    
    @ViewBuilder
    private func NormalModeList() -> some View {
        VStack(spacing: 16) {
            InstalledListSection()
            UnstagedListSection()
        }
    }
    
    // MARK: Installed Lists Section
    
    @ViewBuilder
    private func InstalledListSection() -> some View {
        VStack(spacing: 12) {
            Button {
                withAnimation {
                    showInstalledLists.toggle()
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

                    Text("(\(viewModel.primaryLists.count))")
                        .foregroundColor(.secondary)

                    Image(systemName: showInstalledLists ? SFSymbols.chevronUp : SFSymbols.chevronDown)
                        .bold()
                        .foregroundColor(.red)
                }
            }
            .disabled(viewModel.primaryLists.isEmpty)

            if !viewModel.primaryLists.isEmpty && showInstalledLists {
                if viewModel.isLoadingPrimary {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.primaryLists, id: \.self) { installedList in
                            NavigationLink(value: installedList) {
                                RDListDocumentListItem(list: installedList)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(.red), lineWidth: 4)
        )
    }
    
    // MARK: Unstaged Lists Section
    
    @ViewBuilder
    private func UnstagedListSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("Unstaged")
                    .font(.headline)
                    .foregroundColor(.primary)

                Image(systemName: SFSymbols.arrowUturnBackward)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(8)
            .background(Color(.systemGray5))
            .cornerRadius(6)
            .frame(maxWidth: .infinity)
            
            ScrollView {
                if viewModel.isLoadingSecondary {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.secondaryLists, id: \.self) { unstagedList in
                            NavigationLink(value: unstagedList) {
                                RDListDocumentListItem(list: unstagedList)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onAppear {
                                if unstagedList == viewModel.secondaryLists.last {
                                    Task {
                                        if !viewModel.isLoadingSecondary {
                                            await viewModel.fetchSecondaryLists(initial: false)
                                        }
                                    }
                                }
                            }
                        }  
                    }
                    .padding(8)
                }
            }
            .refreshable {
                await viewModel.fetchPrimaryLists()
                await viewModel.fetchSecondaryLists(initial: true)
            }
        }
    }
    
    // MARK: Search Results List
    
    @ViewBuilder
    private func SearchResultsList() -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.searchResults, id: \.self) { installedList in
                    NavigationLink(value: installedList) {
                        RDListDocumentListItem(list: installedList)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if viewModel.isLoadingSearch {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
        }
        .refreshable {
            await viewModel.fetchSearchResults(query: searchText)
        }
    }
}

#Preview {
    InstalledListDocumentView(path: .constant(.init()))
}
