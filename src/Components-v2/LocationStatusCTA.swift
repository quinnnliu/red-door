//
//  LocationStatusCTA.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/15/26.
//

import SwiftUI

enum LocationStatusCTAAction {
    case navigate(location: DocumentLocation)
}

/// Displays a document's `DocumentLocation` status. Only acts as a button
/// when an `action` is passed and the location is navigable (a pull list or
/// installed list with a real id) — otherwise it's display-only. `isLoading`
/// shows a spinner while the parent fetches the list to navigate to.
struct LocationStatusCTA: View {
    private let location: DocumentLocation
    private let isLoading: Bool
    private let action: ((Any?) -> Void)?
    private let showCaret: Bool

    init(
        location: DocumentLocation,
        isLoading: Bool = false,
        showCaret: Bool = false,
        action: ((Any?) -> Void)? = nil
    ) {
        self.location = location
        self.isLoading = isLoading
        self.showCaret = showCaret
        self.action = action
    }

    var body: some View {
        SmallCTA(
            isButton: action != nil && location.isNavigable,
            type: location.status.isAvailable ? .outline : .red,
            size: .small,
            leadingIcon: location.status.icon,
            trailingIcon: showCaret ? SFSymbols.chevronRight : nil,
            text: location.status.displayTitle,
            semibold: false,
            isLoading: isLoading,
            action: {
                action?(LocationStatusCTAAction.navigate(location: location))
            }
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        LocationStatusCTA(location: DocumentLocation(status: .inStorage, locationId: "warehouse"))
        LocationStatusCTA(location: DocumentLocation(status: .inPullList, locationId: "list"), action: { _ in })
        LocationStatusCTA(location: DocumentLocation(status: .inInstalledList, locationId: "list"), action: { _ in })
        LocationStatusCTA(location: DocumentLocation(status: .inPullList, locationId: "list"), isLoading: true, action: { _ in })
    }
    .padding()
}
