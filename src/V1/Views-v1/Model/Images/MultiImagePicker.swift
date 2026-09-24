//
//  MultiImagePicker.swift
//  RedDoor
//
//  Created by Quinn Liu on 7/30/25.
//

import AVFoundation
import Foundation
import PhotosUI
import SwiftUI

struct MultiCameraPicker: UIViewControllerRepresentable {
    @Binding var selectedRDImages: [RDImage]
    var editIndex: Int
    var dismiss: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: MultiCameraPicker

        init(_ parent: MultiCameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                let newRDImage = RDImage(uiImage: image)
                if parent.editIndex >= 0, parent.editIndex < parent.selectedRDImages.count {
                    // Replace existing image at editIndex
                    parent.selectedRDImages[parent.editIndex] = newRDImage
                } else {
                    // Append if index is invalid or beyond array bounds
                    parent.selectedRDImages.append(newRDImage)
                }
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct MultiLibraryPicker: UIViewControllerRepresentable {
    @Binding var selectedRDImages: [RDImage]
    var editIndex: Int
    var dismiss: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: PHPickerViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiLibraryPicker

        init(_ parent: MultiLibraryPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                        if let image = object as? UIImage {
                            let newRDImage = RDImage(uiImage: image)
                            DispatchQueue.main.async {
                                if self.parent.editIndex >= 0, self.parent.editIndex < self.parent.selectedRDImages.count {
                                    self.parent.selectedRDImages[self.parent.editIndex] = newRDImage
                                } else {
                                    self.parent.selectedRDImages.append(newRDImage)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
