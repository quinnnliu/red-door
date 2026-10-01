//
//  ExpandableSectionView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/30/26.
//

import SwiftUI

enum ExpandableSectionStyle {
    case essentialsItemTypeGroup(type: ItemType, count: Int)
    case pullListRoom(room: RoomV2, itemCount: Int)
    case copyRoom(room: RoomV2, copyableCount: Int, itemCount: Int)
    case installingRoom(room: RoomV2, itemCount: Int)
    case uninstallingRoom(room: RoomV2, itemCount: Int)
    case uninstallEssentials(
        group: EssentialsGroup,
        accessories: Accessories?,
        itemCount: Int,
        destinationLabel: String?,
        destinationSubtitle: String?
    )
}

enum ExpandableSectionAction {
    /// The header was tapped. The section takes no position on what that means —
    /// the style is along for the ride so the consumer can decide, or ignore it.
    case headerAction(style: ExpandableSectionStyle)
    case refreshRoom(roomId: String)
}

struct ExpandableSectionView<Content: View, Trailing: View>: View {
    private let style: ExpandableSectionStyle
    private let action: (Any?) -> Void
    @State private var isExpanded: Bool
    @ViewBuilder private let content: () -> Content
    @ViewBuilder private let trailing: () -> Trailing

    init(
        style: ExpandableSectionStyle,
        isExpanded: Bool = true,
        action: @escaping (Any?) -> Void = { _ in },
        @ViewBuilder trailing: @escaping () -> Trailing,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self._isExpanded = State(initialValue: isExpanded)
        self.action = action
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Header

            if isExpanded && canExpand {
                content()
            }
        }
        .padding(hasCardChrome ? 12 : 0)
        .background(hasCardChrome ? Color(.systemGray6) : Color.clear)
        .cornerRadius(hasCardChrome ? Constants.CornerRadius.medium : 0)
    }
}

extension ExpandableSectionView where Trailing == EmptyView {
    init(
        style: ExpandableSectionStyle,
        isExpanded: Bool = true,
        action: @escaping (Any?) -> Void = { _ in },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(style: style, isExpanded: isExpanded, action: action, trailing: { EmptyView() }, content: content)
    }
}

// MARK: - Header

private extension ExpandableSectionView {
    var Header: some View {
        HStack(spacing: 12) {
            LeadingContent

            CenterContent

            Spacer(minLength: .zero)

            TrailingContent
        }
        .padding(8)
        .background {
            switch style {
            case .installingRoom, .uninstallingRoom:
                Color.red.opacity(0.4)
            default:
                Color.clear
            }
        }
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            action(ExpandableSectionAction.headerAction(style: style))
        }
    }

    @ViewBuilder
    var LeadingContent: some View {
        switch style {
        case .essentialsItemTypeGroup(let type, _):
            Image(systemName: type.icon ?? SFSymbols.ellipsis)
        case .pullListRoom(let room, _), .copyRoom(let room, _, _):
            HStack(spacing: 6) {
                ExpandToggle
                PrimaryImageView(image: room.afterImage ?? room.beforeImage, size: Constants.Image.listItemDefault, isExpandable: false)
            }
        case .installingRoom, .uninstallingRoom:
            ExpandToggle
        case .uninstallEssentials(let group, _, _, _, _):
            HStack(spacing: 6) {
                ExpandToggle
                Text(group.emoji)
                    .font(.title2)
            }
        }
    }

    @ViewBuilder
    var CenterContent: some View {
        switch style {
        case .essentialsItemTypeGroup(let type, _):
            Text(type.title)
                .font(.headline)
                .foregroundColor(.primary)
        case .pullListRoom(let room, _), .installingRoom(let room, _), .uninstallingRoom(let room, _):
            Text(room.displayName)
                .font(.headline)
                .foregroundColor(.primary)
        case .copyRoom(let room, let copyableCount, let itemCount):
            VStack(alignment: .leading, spacing: 4) {
                Text(room.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(copyableCount) of \(itemCount) available")
                    .font(.footnote)
                    .foregroundStyle(copyableCount == itemCount ? Color.secondary : Color.red)
            }
        case .uninstallEssentials(let group, let accessories, let itemCount, _, _):
            VStack(alignment: .leading, spacing: 6) {
                Text(group.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 2) {
                    Text("\(itemCount) items")

                    if let accessories {
                        Text("•")
                        Image(systemName: SFSymbols.booksVerticalFill)
                        Text(accessories.displayName)
                            .lineLimit(1)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.primary)
            }
        }
    }

    @ViewBuilder
    var TrailingContent: some View {
        switch style {
        case .essentialsItemTypeGroup(_, let count):
            HStack(spacing: Constants.Padding(0.5)) {
                Text("(\(count))")
                    .foregroundStyle(.secondary)

                ExpandToggle
            }
        case .pullListRoom(let room, let itemCount):
            HStack(spacing: Constants.Padding(0.5)) {
                ItemCountLabel(itemCount)

                RefreshButton(roomId: room.id)

                Image(systemName: SFSymbols.chevronRight)
                    .frame(24)
                    .foregroundStyle(.gray)
            }
        case .copyRoom(_, _, let itemCount):
            ItemCountLabel(itemCount)
        case .installingRoom(let room, let itemCount), .uninstallingRoom(let room, let itemCount):
            HStack(spacing: Constants.Padding(0.25)) {
                ItemCountLabel(itemCount)

                RefreshButton(roomId: room.id)
            }
        case .uninstallEssentials(_, _, _, let destinationLabel, let destinationSubtitle):
            HStack(spacing: Constants.Padding(0.5)) {
                if let destinationLabel {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(destinationLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)

                        if let destinationSubtitle {
                            Text(destinationSubtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                trailing()
            }
        }
    }
}

// MARK: - Header Components

private extension ExpandableSectionView {
    var ExpandToggle: some View {
        RDButton(
            variant: .outline,
            size: .icon,
            leadingIcon: isExpanded ? SFSymbols.minus : SFSymbols.plus,
            fullWidth: false,
            disabled: !canExpand
        ) {
            withAnimation(Constants.Animation.snappy) {
                isExpanded.toggle()
            }
        }
    }

    func RefreshButton(roomId: String) -> some View {
        RDButton(
            variant: .default,
            size: .icon,
            leadingIcon: SFSymbols.arrowCounterclockwise
        ) {
            action(ExpandableSectionAction.refreshRoom(roomId: roomId))
        }
    }

    func ItemCountLabel(_ itemCount: Int) -> Text {
        Text("(\(itemCount))")
            .font(.caption)
            .foregroundColor(.red)
    }
}

// MARK: - Style Configuration

private extension ExpandableSectionView {
    var count: Int {
        switch style {
        case .essentialsItemTypeGroup(_, let count): count
        case .pullListRoom(_, let itemCount): itemCount
        case .copyRoom(_, _, let itemCount): itemCount
        case .installingRoom(_, let itemCount), .uninstallingRoom(_, let itemCount): itemCount
        case .uninstallEssentials(_, _, let itemCount, _, _): itemCount
        }
    }

    var canExpand: Bool { count > 0 }

    var hasCardChrome: Bool {
        switch style {
        case .essentialsItemTypeGroup, .pullListRoom, .copyRoom, .uninstallEssentials: true
        case .installingRoom, .uninstallingRoom: false
        }
    }
}
