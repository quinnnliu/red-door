//
//  EditPullListViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/1/26.
//

import Foundation
import Firebase

@Observable
final class EditPullListViewModel {
    private let pullListRepo: PullListRepository

    private let original: PullListV2
    var draft: PullListV2

    var isLoading: Bool = false

    var showAlert: Bool = false
    var alertText: String = ""

    // MARK: init

    init(list: PullListV2, pullListRepo: PullListRepository) {
        self.original = list
        self.draft = list
        self.pullListRepo = pullListRepo
    }

    // MARK: canSave

    var canSave: Bool {
        draft.address.isInitialized()
    }

    // MARK: save

    /// Writes only the fields this sheet edits, so a stale `roomIds` or
    /// `unassignedItemIds` on the draft can't clobber concurrent changes.
    @MainActor
    func save() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            var fields: [String: Any] = [:]

            var address = draft.address
            address.town = address.town.lowercased()
            fields[PullListV2.CodingKeys.address.stringValue] = try Firestore.Encoder().encode(address)
            fields[PullListV2.CodingKeys.addressId.stringValue] = draft.addressId
            // Dates go through the encoder so the `@DayGranular` wrapper
            // decides the stored representation, same as `set(document:)`.
            let encoded = try Firestore.Encoder().encode(draft)
            fields[PullListV2.CodingKeys.installDate.stringValue] = encoded[PullListV2.CodingKeys.installDate.stringValue]
            fields[PullListV2.CodingKeys.uninstallDate.stringValue] = encoded[PullListV2.CodingKeys.uninstallDate.stringValue]
            fields[PullListV2.CodingKeys.clientId.stringValue] = draft.clientId
            fields[PullListV2.CodingKeys.squareFootage.stringValue] = (draft.squareFootage?.trimmedOrNil as Any?) ?? FieldValue.delete()

            if let imageField = try await resolveImageField() {
                fields[PullListV2.CodingKeys.image.stringValue] = imageField
            }

            try await pullListRepo.update(id: draft.id, fields: fields)
            return true
        } catch {
            alertText = "[ERROR] Failed updating pull list: \(error.localizedDescription)"
            showAlert = true
            return false
        }
    }

    // MARK: resolveImageField

    /// nil means the image is unchanged and shouldn't be written.
    ///
    /// Storage is only touched for images this list owns. A list copied from an
    /// installed list inherits that list's image reference, so deleting it here
    /// would delete the source's file.
    @MainActor
    private func resolveImageField() async throws -> Any? {
        let owned = original.image?.documentId == original.id

        if var newImage = draft.image, newImage.imageType == .dirty {
            newImage.documentId = draft.id
            let uploaded = try await FirebaseImageManager.shared.uploadImage(newImage, uploadImageType: .listV2)
            if owned, let old = original.image {
                try? await FirebaseImageManager.shared.deleteImage(old, deletedImageType: .listV2)
            }
            draft.image = uploaded
            return try Firestore.Encoder().encode(uploaded)
        }

        if draft.image == nil, let old = original.image {
            if owned {
                try? await FirebaseImageManager.shared.deleteImage(old, deletedImageType: .listV2)
            }
            return FieldValue.delete()
        }

        return nil
    }
}
