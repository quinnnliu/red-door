//
//  SelectAccessoriesSheet.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/30/26.
//

import SwiftUI

/// Paginated single-select accessories picker. Defaults to accessories that are
/// in storage and not already claimed by another essentials group; both are
/// pushed into the Firestore query rather than filtered client-side, so a
/// search can never surface an unpickable accessory.
struct SelectAccessoriesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DocumentListViewModelV2<Accessories>
    @State private var searchFocused: Bool = false
    @State private var showFilterSheet: Bool = false
    @State private var accessoriesTypes: [AccessoriesType] = []

    private let title: String
    private let action: (Any?) -> Void

    init(
        title: String = "Select Accessories",
        defaultFilters: [String: AnyHashable] = [
            "\(Accessories.CodingKeys.location.rawValue).\(DocumentLocation.CodingKeys.status.rawValue)":
                LocationStatus.inStorage.rawValue,
            Accessories.CodingKeys.essentialsGroupId.rawValue: AnyHashable(NSNull())
        ],
        action: @escaping (Any?) -> Void
    ) {
        self.title = title
        self.action = action
        self.viewModel = DocumentListViewModelV2<Accessories>(defaultFilters: defaultFilters)
    }

    var body: some View {
        VStack(spacing: 12) {
            DragIndicator()

            if searchFocused {
                SearchBarV2(isActive: $searchFocused, action: handleAction(_:))
            } else {
                TopBar
            }

            AccessoriesList
        }
        .frameTop()
        .frameHorizontalPadding()
        .task {
            await viewModel.refresh()
        }
        .task {
            accessoriesTypes = (try? await ConfigurationService.shared.getAll(using: AccessoriesTypeRepository())) ?? []
        }
        .sheet(isPresented: $showFilterSheet) {
            // Status is pinned by the default filters, so only the type filter is offered.
            AccessoriesDocumentFilterSheet(
                action: handleAction(_:),
                initialFilters: viewModel.activeFilters,
                availableTypes: accessoriesTypes,
                showsStatus: false
            )
        }
    }
}

// MARK: - Subviews

private extension SelectAccessoriesSheet {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                Text(title)
                    .font(.system(.title2, design: .default))
                    .bold()
                    .foregroundStyle(.red)
            },
            header: {
                EmptyView()
            },
            trailingView: {
                HStack(spacing: 8) {
                    RDButton(variant: viewModel.activeFiltersApplied ? .red : .outline, size: .icon, leadingIcon: SFSymbols.sliderHorizontal3, fullWidth: false) {
                        showFilterSheet = true
                    }
                    RDButton(variant: .outline, size: .icon, leadingIcon: SFSymbols.magnifyingglass, fullWidth: false, disabled: viewModel.activeFiltersApplied) {
                        withAnimation(Constants.Animation.snappy) {
                            searchFocused = true
                        }
                    }
                }
            }
        )
    }

    var AccessoriesList: some View {
        DocumentListSection(
            viewModel: viewModel,
            noMoreLabel: "No More Accessories",
            action: handleAction(_:),
            rowContent: { accessories in
                AccessoriesListItemView(
                    accessories,
                    action: handleAction(_:),
                    actionType: .select(accessories)
                )
            }
        )
    }
}

// MARK: - handleAction

private extension SelectAccessoriesSheet {
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
        case let accessoriesAction as AccessoriesListItemAction:
            switch accessoriesAction {
            case .select(let accessories):
                action(AccessoriesListItemAction.select(accessories))
                dismiss()
            default:
                break
            }
        default:
            break
        }
    }
}
