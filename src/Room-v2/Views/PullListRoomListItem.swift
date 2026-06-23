//
//  PullListRoomListItem.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import SwiftUI

struct PullListRoomListItem: View {
    let room: RoomV2
    let items: [ItemV2]
    let action: (Any?) -> Void
    
    @State private var showRoomPreview: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            RoomPreviewHeader
            
            if !items.isEmpty && showRoomPreview {
                withAnimation {
                    RoomPreview
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

extension PullListRoomListItem {
    
    // MARK: RoomHeader
    private var RoomPreviewHeader: some View {
        HStack(spacing: 12) {
            RDButton(
                variant: .outline,
                size: .icon,
                leadingIcon: showRoomPreview ? SFSymbols.minus : SFSymbols.plus,
                iconBold: true,
                fullWidth: false
            ) {
                showRoomPreview.toggle()
            }
            .disabled(items.isEmpty)
            
            Text(room.displayName)
                .foregroundColor(.primary)
                .bold()
            
            Spacer()
            
            (
                Text("Items: ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                +
                Text("\(items.count)")
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
            
            Image(systemName: SFSymbols.chevronRight)
                .frame(32)
                .foregroundStyle(.gray)
        }
    }
    
    // MARK: Room Preview
    
    private var RoomPreview: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: 8) {
            ForEach(items, id: \.self) { item in
                ItemListItem(item: item)
            }
        }
    }
    
    // MARK: Item List Item
    @ViewBuilder
    private func ItemListItem(item: ItemV2) -> some View {
        NavigationLink(value: NavigationDestination.pullListItemDetailView(item: item, room: room)
        ) {
            HStack(alignment: .center, spacing: 12) {
                
                ItemListItemImage(item.primaryImage)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    HStack(spacing: 4) {
                        Image(systemName: item.type.icon ?? SFSymbols.ellipsis)
                            .foregroundColor(.secondary)
                        
                        if let color = item.color.color {
                            Image(systemName: SFSymbols.circleFill)
                                .foregroundColor(color)
                        }
                    }
                    .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(item.attention ? Color.yellow.opacity(0.75) : item.status == .inStorage ? Color(.systemGray3) : Color.red, lineWidth: 2)
            )
        }
    }
}

enum RoomListItemViewAction {
    case refreshRoom(roomId: String)
}
