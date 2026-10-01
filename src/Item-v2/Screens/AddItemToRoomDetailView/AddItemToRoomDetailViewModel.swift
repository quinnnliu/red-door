//
//  AddItemToRoomDetailViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 5/30/26.
//

import Foundation
import SwiftUI

@Observable
final class AddItemToRoomDetailViewModel {
    let roomRepo: RoomRepository<PullListV2>
    let itemRepo: ItemRepository = .init()
    var room: RoomV2
    let item: ItemV2
    private let essentialsRepo: EssentialsRepository = .init()
    var essentialsGroup: EssentialsGroup?

    var isLoading: Bool = false
    
    var selectedRDImage: RDImage?
    var isImageSelected: Bool = false
    var alertMessage: String = ""
    var showAlert: Bool = false
    
    init(
        item: ItemV2,
        room: RoomV2
    ) {
        self.roomRepo = RoomRepository<PullListV2>(room: room)
        self.room = room
        self.item = item
    }
}

extension AddItemToRoomDetailViewModel {
    func loadEssentialsGroup() async {
        guard let groupId = item.essentialGroupId else { return }
        do { essentialsGroup = try await essentialsRepo.get(id: groupId) }
        catch { print("error loading essentials group: \(error)") }
    }

    @MainActor
    func addItemToRoom() async -> Bool {
        do {
            try await roomRepo.addItems(
                [item.id],
                toRoomId: room.id,
                itemRepo: itemRepo
            )
            alertMessage = "Added \(item.displayName) to \(room.displayName)"
            showAlert = true
            return true
        } catch {
            alertMessage = "Failed to add \(item.displayName) to \(room.displayName)"
            showAlert = true
            print("[ERROR]: Failed to add \(item.displayName) to \(room.displayName): \(error.localizedDescription)")
            return false
        }
    }
}
