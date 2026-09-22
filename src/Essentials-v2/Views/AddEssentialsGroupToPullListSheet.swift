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

    init(action: @escaping (Any?) -> Void) {
        self.action = action
        self.viewModel = DocumentListViewModelV2<PullListV2>()
    }

    var body: some View {
        VStack(spacing: 12) {
            DragIndicator()

            TopBar

            PullListList
        }
        .frameTop()
        .frameHorizontalPadding()
        .task {
            await viewModel.refresh()
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
                EmptyView()
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
