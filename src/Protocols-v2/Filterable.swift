//
//  Filterable.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/22/26.
//

import SwiftUI

protocol Filterable: CaseIterable, Hashable, Codable {
    var title: String { get }
    var icon: String? { get }
    var color: Color? { get }
}
