//
//  AddEssentialsGroupToPullListSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/21/26.
//

import SwiftUI

struct AddEssentialsGroupToPullListSheet: View {
    @State private var viewModel: DocumentListViewModelV2<PullListV2>
    @Environment(\.dismiss) private var dismiss

    private let action: (Any?) -> Void

    @State private var searchFocused: Bool = false
    @State private var showFilterSheet: Bool = false

    init(action: @escaping (Any?) -> Void) {
        self.action = action
        self.viewModel = DocumentListViewModelV2<PullListV2>()
    }

    var body: some View {
        VStack(spacing: 12) {
            DragIndicator()

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
        .sheet(isPresented: $showFilterSheet) {
            PullListV2DocumentFilterSheet(
                initialFilters: viewModel.activeFilters,
                action: handleAction(_:)
            )
        }
    }
}

// MARK: - Subviews

private extension AddEssentialsGroupToPullListSheet {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                Text("Select Pull List")
                    .font(.system(.title2, design: .default))
                    .bold()
                    .foregroundStyle(.red)
            },
            header: {
                EmptyView()
            },
            trailingView: {
                HStack(spacing: 8) {
                    RDButton(variant: viewModel.activeFiltersApplied ? .red : .outline, size: .icon, leadingIcon: SFSymbols.sliderHorizontal3, iconBold: true, fullWidth: false) {
                        showFilterSheet = true
                    }
                    RDButton(variant: .outline, size: .icon, leadingIcon: SFSymbols.magnifyingglass, iconBold: true, fullWidth: false) {
                        withAnimation(Constants.Animation.snappy) {
                            searchFocused = true
                        }
                    }
                }
            }
        )
    }

    var PullListList: some View {
        DocumentListSection(
            viewModel: viewModel,
            noMoreLabel: "No More Pull Lists",
            action: handleAction(_:),
            rowContent: { pullList in
                PullListV2ListItem(
                    list: pullList,
                    action: handleAction(_:),
                    actionType: .assignEssentialsToList(list: pullList)
                )
            }
        )
    }

    func handleAction(_ emittedAction: Any?) {
        switch emittedAction {
        case let searchAction as SearchBarAction:
            Task { await viewModel.handleSearchAction(searchAction) }
        case let filterAction as DocumentFilterSheetAction:
            switch filterAction {
            case .applyFilters(let filters):
                Task { await viewModel.setFilters(filters) }
            }
        case let sectionAction as DocumentListSectionAction:
            switch sectionAction {
            case .loadMore:
                Task { await viewModel.loadMore() }
            }
        case let listAction as PullListListItemAction:
            switch listAction {
            case .assignEssentialsToList(let list):
                action(PullListListItemAction.assignEssentialsToList(list: list))
                dismiss()
            default:
                break
            }
        default:
            break
        }
    }
}
