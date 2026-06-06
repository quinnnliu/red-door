//
//  RoomListItemView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import SwiftUI

struct RoomListItemView: View {
    let room: RoomV2
    let rooms: [RoomV2]
    let items: [ItemV2]
    let list: PullListV2
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

extension RoomListItemView {
    
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
        NavigationLink(value: NavigationDestination.pullListItemDetailView(item: item, room: room, rooms: rooms, list: list)
        ) {
            HStack(alignment: .center, spacing: 12) {
                
                ItemPreviewImageV2(item: item)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    HStack(spacing: 4) {
                        Image(systemName: item.type.icon)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: SFSymbols.circleFill)
                            .foregroundColor(item.color.color)
                    }
                    .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(item.attention ? Color.yellow.opacity(0.75) : item.isAvailable ? Color(.systemGray3) : Color.red, lineWidth: 2)
            )
        }
    }
}

import CachedAsyncImage

// TODO: make a better version for this that can exist on its own
struct ItemPreviewImageV2: View {
    let item: ItemV2
    var size: CGFloat = 48
    
    var body: some View {
        Group {
            if item.primaryImage.imageExists, let imageURL = item.primaryImage.imageURL {
                ItemCachedAsyncImage(imageURL: imageURL)
            } else {
                Color.gray
                    .overlay(
                        Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(size)
        .cornerRadius(8)
    }
    
    // MARK: Item Cached Async Image
    
    @ViewBuilder
    private func ItemCachedAsyncImage(imageURL: URL) -> some View {
        CachedAsyncImage(url: imageURL) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity)
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                Color.gray
                    .overlay(
                        Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                            .foregroundColor(.white)
                    )
            @unknown default:
                Color.gray
                    .overlay(
                        Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                            .foregroundColor(.white)
                    )
            }
        }
    }
}



enum RoomListItemViewAction {
    case refreshRoom(roomId: String)
}
