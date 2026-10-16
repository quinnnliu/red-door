//
//  LocationNavigator.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/16/26.
//

import Foundation

/// Fetches the list a `LocationStatusCTA` points to and builds its detail
/// destination. Held as `@State` by any screen with a navigable location CTA;
/// the screen pushes the returned destination itself.
@MainActor
@Observable
final class LocationNavigator {
    private let pullListRepo = PullListRepository()
    private let installedListRepo = InstalledListRepository()

    private(set) var isNavigating: Bool = false
    var showAlert: Bool = false
    var alertMessage: String = ""

    /// Returns nil for storage, an empty id, a fetch already in flight, or a failed fetch.
    func destination(
        for location: DocumentLocation,
        essentialsGroupNavigable: Bool = true
    ) async -> NavigationDestination? {
        guard !isNavigating, location.isNavigable else { return nil }
        isNavigating = true
        defer { isNavigating = false }

        do {
            switch location.status {
            case .inPullList:
                let list = try await pullListRepo.get(id: location.locationId)
                return .pullListDetailView(list, essentialsGroupNavigable: essentialsGroupNavigable)
            case .inInstalledList:
                let list = try await installedListRepo.get(id: location.locationId)
                return .installedListDetailView(list, essentialsGroupNavigable: essentialsGroupNavigable)
            case .inStorage:
                return nil
            }
        } catch {
            alertMessage = "Couldn't open location: \(error.localizedDescription)"
            showAlert = true
            return nil
        }
    }
}
