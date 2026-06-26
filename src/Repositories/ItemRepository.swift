//
//  ItemRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import Firebase

final class ItemRepository: GenericRepository<ItemV2> {
    
    // MARK: maxItemNumber

    func maxItemNumber(forModelId modelId: String) async throws -> Int {
        let snapshot = try await collectionRef
            .whereField(ItemV2.CodingKeys.modelId.stringValue, isEqualTo: modelId)
            .order(by: ItemV2.CodingKeys.itemNumber.stringValue, descending: true)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.first
            .flatMap { $0.data()["item_number"] as? Int } ?? 0
    }

    // MARK: markItemNeedsAttention
    
    func markItemNeedsAttention(id: String, description: String?) async throws {
        var fields: [String: AnyHashable] = [ItemV2.CodingKeys.attention.stringValue: true]
        if let description = description {
            fields.updateValue(description, forKey: ItemV2.CodingKeys.description.stringValue)
        }
        try await update(id: id, fields: fields)
    }
    
    
}

// MARK: - updateItemEssentialsGroup

extension ItemRepository {
    
    func updateItemEssentialsGroup(id: String, essentialsGroupId: String) async throws {
        try await update(id: id, fields: [
            ItemV2.CodingKeys.essentialGroupId.stringValue: essentialsGroupId
        ])
    }
    
    // MARK: batch
    
    func updateItemEssentialsGroup(id: String, essentialsGroupId: String, inBatch batch: WriteBatch) {
        update(
            id: id,
            fields: [
                ItemV2.CodingKeys.essentialGroupId.stringValue: essentialsGroupId
            ],
            inBatch: batch
        )
    }
    
    // MARK: transaction
    
    func updateItemEssentialsGroup(id: String, essentialsGroupId: String, in transaction: Transaction) {
        update(
            id: id,
            fields: [
                ItemV2.CodingKeys.essentialGroupId.stringValue: essentialsGroupId
            ],
            transaction: transaction
        )
    }
}
