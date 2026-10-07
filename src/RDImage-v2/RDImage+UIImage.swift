//
//  RDImage+UIImage.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/05/26.
//

import Kingfisher
import UIKit

extension RDImage {

    /// A `UIImage` for contexts that can't wait on `KFImage`'s async load, such
    /// as `ImageRenderer` snapshots. Goes through Kingfisher's memory and disk
    /// cache, so anything already shown by `RDImageView` is not downloaded again.
    ///
    /// Prefers an in-memory `uiImage` (not yet uploaded), then the thumbnail,
    /// which is what `RDImageView` loads at small sizes and so is likely cached.
    /// Returns nil when there is no image or the load fails.
    func loadUIImage(preferThumbnail: Bool = true) async -> UIImage? {
        if let uiImage { return uiImage }

        let url = preferThumbnail ? (thumbnailURL ?? imageURL) : (imageURL ?? thumbnailURL)
        guard let url,
              let result = try? await KingfisherManager.shared.retrieveImage(with: .network(url))
        else { return nil }
        return result.image
    }
}
