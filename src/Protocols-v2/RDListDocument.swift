//
//  RDListDocument.swift
//  RedDoor
//
//  Created by Quinn Liu on 09/30/26.
//

/// A document whose rooms live in a `rooms` subcollection beneath it.
///
/// `RoomV2` is byte-identical in both `pull_list_v2` and `installed_list_v2`,
/// so the parent type is the only thing that says where a room actually lives
/// and what an item added to it becomes. Making `RoomRepository` generic over
/// this turns "wrong collection" into a compile error.
protocol RDListDocument: RDDocument {
    static var listKind: RDListKind { get }

    /// False once the list is a historical record. An uninstalled list still
    /// renders its rooms, but must stop accepting items into them.
    var acceptsNewItems: Bool { get }
}

extension RDListDocument {
    var acceptsNewItems: Bool { true }

    /// Where an item lands when added to one of this list's rooms.
    static var itemLocationStatus: LocationStatus { listKind.itemLocationStatus }
}

/// Erased form of `RDListDocument`, for the few places that have to carry
/// "which kind of list" as a value rather than a type: `NavigationDestination`
/// is `Hashable` and stored in a `NavigationPath`, and a generic enum can't be
/// registered with a single `navigationDestination(for:)`.
///
/// Derive it from the type (`InstalledListV2.listKind`) rather than writing the
/// case by hand, so a call site can't label a room with the wrong kind.
enum RDListKind: String, Hashable, Codable {
    case pullList
    case installedList

    var itemLocationStatus: LocationStatus {
        switch self {
        case .pullList: .inPullList
        case .installedList: .inInstalledList
        }
    }
}
