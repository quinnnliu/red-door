//
//  ItemRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import Firebase

final class ItemRepository: GenericRepository<ItemV2> {
    func markItemNeedsAttention(id: String, description: String?) async throws {
        var fields: [String: AnyHashable] = [ItemV2.CodingKeys.attention.stringValue: true]
        if let description = description {
            fields.updateValue(description, forKey: ItemV2.CodingKeys.description.stringValue)
        }
        try await update(id: id, fields: fields)
    }
}

// MARK: - Batch
extension ItemRepository {
//    func createItemFromModel(model: ModelV2, forBatch batch: WriteBatch) throws {
//        
//        try batch.setData(from: item, forDocument: collectionRef.document(item.id))
//    }
}

// MARK: - Transaction
extension ItemRepository {
    
}
