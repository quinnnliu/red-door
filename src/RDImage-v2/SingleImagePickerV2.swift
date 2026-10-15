//
//  SingleImagePickerV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/10/26.
//

import AVFoundation
import Foundation
import PhotosUI
import SwiftUI

/// Pickers hand back the raw `UIImage`. The screen's ViewModel wraps it in an
/// `RDImage`, since only it knows which document will own the image.
struct SingleCameraPickerV2: UIViewControllerRepresentable {
    var action: (UIImage?) -> Void

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
        let parent: SingleCameraPickerV2

        init(_ parent: SingleCameraPickerV2) {
            self.parent = parent
        }

        func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.action(image)
            }
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            parent.action(nil)
        }
    }
}

struct SingleLibraryPickerV2: UIViewControllerRepresentable {
    var action: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        let nav = UINavigationController(rootViewController: picker)
        return nav
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: SingleLibraryPickerV2

        init(_ parent: SingleLibraryPickerV2) {
            self.parent = parent
        }

        func picker(_: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if results.isEmpty {
                // User canceled the selection
                parent.action(nil)
                return
            }

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                parent.action(nil)
                return
            }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    // A failed load counts as a cancel rather than an image with no content.
                    self.parent.action(image as? UIImage)
                }
            }
        }

        @objc func didTapCancel() {
            parent.action(nil)
        }
    }
}
