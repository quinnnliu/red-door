//
//  PullListV2DetailsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/17/26.
//

import SwiftUI

struct PullListV2DetailsView: View {
    @State private var viewModel: PullListV2DetailsViewModel
    @State private var showAddRoomsSheet: Bool = false

    init(list: PullListV2) {
        viewModel = PullListV2DetailsViewModel(from: list)
    }

    var body: some View {
        VStack(spacing: 16) {
            TopBar

            if viewModel.isLoading && viewModel.rooms.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text("Error")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding()
            }

            if !viewModel.rooms.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rooms")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.rooms, id: \.id) { room in
                                RoomListItemView(
                                    room: room,
                                    items: viewModel.itemsByRoom[room.id] ?? [],
                                    onRefresh: { viewModel.refreshRoom(room.id) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                Text("No rooms")
            }

            Spacer()
        }
        .frameTop()
        .frameHorizontalPadding()
        .toolbar(.hidden)
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
}

extension PullListV2DetailsView {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton()
            },
            header: {
                HStack {
                    Text("Address:")
                        .bold()
                        .foregroundStyle(.red)
                    Text(viewModel.pullListState.address.getStreetAddress() ?? viewModel.pullListState.address.formattedAddress)
                }
            },
            trailingView: {
                HStack(spacing: 8) {
                    RDButton(
                        variant: .outline,
                        size: .icon,
                        leadingIcon: SFSymbols.arrowCounterclockwise
                    ) {
                        viewModel.refreshPullList()
                    }

                    RDButton(
                        variant: .red,
                        size: .icon,
                        leadingIcon: SFSymbols.plus
                    ) {
                        showAddRoomsSheet = true
                    }
                }
            }
        )
    }
}

struct RoomListItemView: View {
    let room: RoomV2
    let items: [ItemV2]
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(room.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(items.count) items")
                    .font(.caption)
                    .foregroundColor(.gray)
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }

            if items.isEmpty {
                Text("No items")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(items, id: \.id) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text(item.name)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
