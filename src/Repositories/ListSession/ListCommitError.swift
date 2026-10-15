//
//  ListCommitError.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/15/26.
//

import Foundation

/// Thrown by an install or uninstall commit that re-read the list inside its
/// transaction and found it differs from what the user reviewed. Nothing has
/// been written when one of these is thrown.
enum ListCommitError: LocalizedError {
    /// Another user took over the session after this client last saw it.
    case notOwner
    /// Install: the pull list still has items in its unassigned pool.
    case unassignedItems(count: Int)
    /// Install: rooms hold items the user never saw.
    case unreviewedItems(count: Int)
    /// Uninstall: room items that have no destination yet.
    case unroutedItems(count: Int)
    /// The essentials group differs from the reviewed one, or has no destination.
    case essentialsChanged

    var errorDescription: String? {
        switch self {
        case .notOwner:
            "Another user took over this session. You are now view-only."
        case .unassignedItems(let count):
            "This list has \(count) unassigned \(count == 1 ? "item" : "items"). Assign \(count == 1 ? "it" : "them") to a room or storage before installing."
        case .unreviewedItems(let count):
            "This list changed since you reviewed it. \(count) new \(count == 1 ? "item was" : "items were") added. Review the list and confirm again."
        case .unroutedItems(let count):
            "This list changed since you reviewed it. \(count) \(count == 1 ? "item needs" : "items need") a destination."
        case .essentialsChanged:
            "The essentials group on this list changed. Review it and confirm again."
        }
    }
}
