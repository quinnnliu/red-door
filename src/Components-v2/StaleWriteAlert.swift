//
//  StaleWriteAlert.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/29/26.
//

import SwiftUI

/// Presents a `StaleWriteError` raised by a write from a screen that was out of
/// date. When the list or room is gone, acknowledging the alert resets the
/// selected tab's navigation path, because nothing on the stack is usable.
struct StaleWriteAlertModifier: ViewModifier {
    @Binding var error: StaleWriteError?
    @Environment(NavigationCoordinator.self) private var coordinator

    func body(content: Content) -> some View {
        content.alert(
            "Out of Date",
            isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            ),
            presenting: error
        ) { error in
            Button("OK", role: .cancel) {
                if error.resetsNavigation {
                    coordinator.resetSelectedPath()
                }
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

extension View {
    func staleWriteAlert(_ error: Binding<StaleWriteError?>) -> some View {
        modifier(StaleWriteAlertModifier(error: error))
    }
}
