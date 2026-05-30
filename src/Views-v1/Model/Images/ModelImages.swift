//
//  ModelImages.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/6/25.
//

import SwiftUI

struct ModelImages: View {
    @Binding var model: Model

    @Binding var selectedRDImage: RDImage?
    @Binding var isImageSelected: Bool
    @Binding var isEditing: Bool

    var body: some View {
        Group {
            if !model.primaryImageExists {
                HStack {
                    Spacer()

                    ModelPrimaryImage(primaryRDImage: $model.primaryImage,
                                      selectedRDImage: $selectedRDImage,
                                      isImageSelected: $isImageSelected,
                                      isEditing: $isEditing)

                    Spacer()
                }
            } else {
                HStack(spacing: 0) {
                    ModelPrimaryImage(primaryRDImage: $model.primaryImage,
                                      selectedRDImage: $selectedRDImage,
                                      isImageSelected: $isImageSelected,
                                      isEditing: $isEditing)

                    Spacer()

                    ModelSecondaryImages(secondaryRDImages: $model.secondaryImages,
                                         selectedRDImage: $selectedRDImage,
                                         isImageFullScreen: $isImageSelected,
                                         isEditing: $isEditing)
                }
            }
        }
    }
}
