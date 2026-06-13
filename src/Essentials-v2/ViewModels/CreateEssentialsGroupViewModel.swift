//
//  CreateEssentialsGroupViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/13/26.
//

import SwiftUI

@Observable
final class CreateEssentialsGroupViewModel {
    private let essentialsRepo: EssentialsRepository = .init()
    private let essentialsGroupTypeRepo: EssentialsGroupTypeRepository = .init()

    var selectedGroupType: EssentialsGroupType?
    var existingGroupTypes: [EssentialsGroupType] = []
    var newGroupTypeName: String = ""

    var isLoading: Bool = false

    func loadGroupTypes() async {
        // TODO: use DocumentListViewModelV2<EssentialsGroupType> or a one-shot fetch
    }

    // MARK: createEssentialsGroup

    func createEssentialsGroup() async {
        guard let groupType = selectedGroupType else { return }

        let group = EssentialsGroup(
            displayName: groupType.displayName,
            essentialsTypeId: groupType.id
        )

        isLoading = true
        defer { isLoading = false }

        do {
            try essentialsRepo.set(document: group)
        } catch {
            print("Error creating essentials group: \(error)")
        }
    }
}
