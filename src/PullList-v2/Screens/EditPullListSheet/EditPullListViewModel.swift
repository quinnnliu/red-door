//
//  EditPullListViewModel.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/1/26.
//

import SwiftUI
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

            let (imageField, imageCleanup) = try await resolveImageField()
            if let imageField {
                fields[PullListV2.CodingKeys.image.stringValue] = imageField
            }

            try await pullListRepo.update(id: draft.id, fields: fields)

            // After the write, so a failed save never points the list at a
            // deleted file. A list copied from an installed list before images
            // were copied can still reference that list's file, so only files
            // this list owns are deleted.
            if let imageCleanup, imageCleanup.documentId == draft.id {
                try? await FirebaseImageManager.shared.delete(imageCleanup, type: .listV2)
            }
            return true
        } catch {
            alertText = "[ERROR] Failed updating pull list: \(error.localizedDescription)"
            showAlert = true
            return false
        }
    }

    // MARK: resolveImageField

    /// `field` is nil when the image is unchanged and shouldn't be written.
    /// `cleanup` is the replaced or removed image to delete once the write commits.
    @MainActor
    private func resolveImageField() async throws -> (field: Any?, cleanup: RDImage?) {
        let (persisted, cleanup) = try await FirebaseImageManager.shared.resolve(
            original: original.image,
            updated: draft.image,
            type: .listV2
        )
        guard persisted?.id != original.image?.id else { return (nil, nil) }

        draft.image = persisted
        guard let persisted else { return (FieldValue.delete(), cleanup) }
        return (try Firestore.Encoder().encode(persisted), cleanup)
    }

    // MARK: Image

    func setImage(_ uiImage: UIImage) {
        draft.image = RDImage(uiImage: uiImage, documentId: draft.id)
    }

    /// Storage is only touched on save, so cancelling leaves it alone.
    func clearImage() {
        draft.image = nil
    }
}
