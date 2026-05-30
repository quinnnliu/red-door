//
//  ImageSourceEnum.swift
//  RedDoor
//
//  Created by Quinn Liu on 7/30/25.
//

import Foundation

enum ImageSourceEnum: String, Identifiable {
    var id: String {
        rawValue
    }

    case library, camera
}
