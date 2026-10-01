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
    case installingRoom(room: RoomV2, itemCount: Int)
}

enum ExpandableSectionAction {
    /// The header was tapped. The section takes no position on what that means —
    /// the style is along for the ride so the consumer can decide, or ignore it.
    case headerAction(style: ExpandableSectionStyle)
    case refreshRoom(roomId: String)
}

struct ExpandableSectionView<Content: View>: View {
    private let style: ExpandableSectionStyle
    private let action: (Any?) -> Void
    @State private var isExpanded: Bool
    @ViewBuilder private let content: () -> Content

    init(
        style: ExpandableSectionStyle,
        isExpanded: Bool = true,
        action: @escaping (Any?) -> Void = { _ in },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self._isExpanded = State(initialValue: isExpanded)
        self.action = action
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
            case .installingRoom:
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
        case .pullListRoom(let room, _):
            HStack(spacing: 6) {
                ExpandToggle
                PrimaryImageView(image: room.afterImage ?? room.beforeImage, size: Constants.Image.listItemDefault, isExpandable: false)
            }
        case .installingRoom:
            EmptyView()
        }
    }

    @ViewBuilder
    var CenterContent: some View {
        switch style {
        case .essentialsItemTypeGroup(let type, _):
            Text(type.title)
                .font(.headline)
                .foregroundColor(.primary)
        case .pullListRoom(let room, _), .installingRoom(let room, _):
            Text(room.displayName)
                .font(.headline)
                .foregroundColor(.primary)
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
        case .installingRoom(let room, let itemCount):
            HStack(spacing: Constants.Padding(0.25)) {
                ItemCountLabel(itemCount)

                RefreshButton(roomId: room.id)

                ExpandToggle
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
        case .installingRoom(_, let itemCount): itemCount
        }
    }

    var canExpand: Bool { count > 0 }

    /// Installing rows sit inside an already-padded list, so they supply no
    /// chrome of their own.
    var hasCardChrome: Bool {
        switch style {
        case .essentialsItemTypeGroup, .pullListRoom: true
        case .installingRoom: false
        }
    }
}
