//
//  RoomListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/25/26.
//

import SwiftUI

enum RoomListItemStyle {
    case pullListDetails
    case installingPullList
}

enum RoomListItemViewAction {
    case navigate(room: RoomV2)
    case refreshRoom(roomId: String)
}

struct RoomListItemView<Content: View>: View {
    let room: RoomV2
    let itemCount: Int
    let style: RoomListItemStyle
    let action: (Any?) -> Void
    @ViewBuilder let content: () -> Content

    @State private var showContent: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                action(RoomListItemViewAction.navigate(room: room))
            } label: {
                Header
            }
            
            if showContent && itemCount > 0 {
                content()
            }
        }
        .padding(style == .pullListDetails ? 12 : 0)
        .background(style == .pullListDetails ? Color(.systemGray6) : Color.clear)
        .cornerRadius(style == .pullListDetails ? 8 : 0)
    }

    // MARK: Header

    private var Header: some View {
        HStack(spacing: 0) {
            HeaderLeadingContent

            Spacer()

            HeaderTrailingContent
        }
    }
}

private extension RoomListItemView {
    var HeaderLeadingContent: some View {
        HStack(spacing: 12) {
            if style == .pullListDetails {
                ExpandToggle
            }

            Text(room.displayName)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
    
    var HeaderTrailingContent: some View {
        HStack(spacing: 12) {
            (
                Text("Items: ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                +
                Text("\(itemCount)")
                    .font(.caption)
                    .foregroundColor(.red)
            )

            RDButton(
                variant: .default,
                size: .icon,
                leadingIcon: SFSymbols.arrowCounterclockwise
            ) {
                action(RoomListItemViewAction.refreshRoom(roomId: room.id))
            }

            if style == .installingPullList {
                ExpandToggle
            }

            if style == .pullListDetails {
                Button {
                    action(RoomListItemViewAction.navigate(room: room))
                } label: {
                    Image(systemName: SFSymbols.chevronRight)
                        .frame(32)
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var ExpandToggle: some View {
        RDButton(
            variant: .outline,
            size: .icon,
            leadingIcon: showContent ? SFSymbols.minus : SFSymbols.plus,
            iconBold: true,
            fullWidth: false,
            disabled: itemCount == 0
        ) {
            withAnimation(Constants.Animation.snappy) {
                showContent.toggle()
            }
        }
    }
}
