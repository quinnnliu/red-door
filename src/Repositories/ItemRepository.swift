//
//  ItemRepository.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import Firebase

enum ItemDeleteError: LocalizedError {
    case assignedToList
    case inEssentialsGroup

    var errorDescription: String? {
        switch self {
        case .assignedToList: "Return this item to storage before deleting it."
        case .inEssentialsGroup: "Remove this item from its essentials group before deleting it."
        }
    }
}

final class ItemRepository: GenericRepository<ItemV2> {
    
    // MARK: maxItemNumber

    func maxItemNumber(forModelId modelId: String) async throws -> Int {
        try await maxNumber(
            filteredBy: ItemV2.CodingKeys.modelId.stringValue,
            equalTo: modelId,
            numberField: ItemV2.CodingKeys.itemNumber.stringValue
        )
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

// MARK: - Delete

extension ItemRepository {
    func deleteItem(id itemId: String) async throws {
        let deleted = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let item = try self.get(id: itemId, transaction: transaction)
                if let blocker = item.deleteErrorReason { throw blocker }

                self.delete(id: itemId, transaction: transaction)
                return item
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let item = deleted as? ItemV2 else { return }

        do {
            try await FirebaseImageManager.shared.deleteDocumentImages(ownerId: item.id, imageType: .item)
        } catch {
            print("[WARN]: Deleted item \(itemId) but failed to clean up its images: \(error.localizedDescription)")
        }
    }
}
