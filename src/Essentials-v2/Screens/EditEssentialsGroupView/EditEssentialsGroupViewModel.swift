//
//  EditEssentialsGroupViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/12/26.
//

import SwiftUI

@Observable
final class EditEssentialsGroupViewModel {
    private let essentialsGroupTypeRepo: EssentialsGroupTypeRepository
    private let configService: ConfigurationService

    // MARK: - Group Type Picker State

    var groupTypes: [EssentialsGroupType] = []
    var showGroupTypePicker: Bool = false
    var showNewTypeField: Bool = false
    var newGroupTypeName: String = ""
    var newGroupTypeEmoji: String = ""

    var newGroupTypeValid: Bool {
        let name = newGroupTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && (newGroupTypeEmoji.isEmpty || newGroupTypeEmoji.isSingleEmoji)
    }

    // MARK: - Loading

    var isLoading: Bool = false

    init(
        essentialsGroupTypeRepo: EssentialsGroupTypeRepository,
        configService: ConfigurationService = .shared
    ) {
        self.essentialsGroupTypeRepo = essentialsGroupTypeRepo
        self.configService = configService
    }

    // MARK: - Load

    func loadGroupTypes() async {
        do {
            groupTypes = try await configService.getAll(using: essentialsGroupTypeRepo)
        } catch {
            print("Error loading group types: \(error)")
        }
    }

    // MARK: - Create Group Type

    func createAndSelectNewGroupType() -> EssentialsGroupType? {
        let name = newGroupTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let emoji = newGroupTypeEmoji.isSingleEmoji ? newGroupTypeEmoji : "⭐️"
        let newType = EssentialsGroupType(baseName: name, emoji: emoji)

        do {
            try essentialsGroupTypeRepo.set(document: newType)
            configService.invalidate(EssentialsGroupType.self)
            groupTypes.append(newType)
            newGroupTypeName = ""
            newGroupTypeEmoji = ""
            showNewTypeField = false
            return newType
        } catch {
            print("Error creating group type: \(error)")
            return nil
        }
    }
}
