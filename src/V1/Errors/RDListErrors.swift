//
//  RDListErrors.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/5/25.
//

import Foundation

enum PullListValidationError: Error {
    case itemNotAvailable(id: String)
    case itemDoesNotExist(id: String)
    case modelDoesNotExist(id: String)
    case modelAvailableCountInvalid(id: String)
}

enum InstalledFromPullError: Error {
    case creationFailed
}
