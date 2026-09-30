//
//  Date+Display.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/29/26.
//

import Foundation

extension Date {
    var displayDate: String {
        formatted(.dateTime.year().month().day())
    }
}
