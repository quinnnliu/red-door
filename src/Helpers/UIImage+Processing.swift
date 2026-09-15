//
//  UIImage+Processing.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/14/26.
//

import UIKit

extension UIImage {
    func resized(toMaxDimension max: CGFloat) -> UIImage {
        let scale = min(max / size.width, max / size.height, 1.0)
        guard scale < 1.0 else { return self }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
