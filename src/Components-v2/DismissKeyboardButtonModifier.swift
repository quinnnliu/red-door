//
//  DismissKeyboardButtonModifier.swift
//  RedDoor
//
//  Created by Quinn Liu on 11/11/26.
//

import SwiftUI

/// Adds a button to the keyboard toolbar that clears the given focus state,
/// dismissing the keyboard. Only shows inside a `NavigationStack`.
struct DismissKeyboardButtonModifier: ViewModifier {
    private let isFocused: FocusState<Bool>.Binding
    private let label: String

    init(isFocused: FocusState<Bool>.Binding, label: String = "Dismiss") {
        self.isFocused = isFocused
        self.label = label
    }

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(label) {
                    isFocused.wrappedValue = false
                }
            }
        }
    }
}

extension View {
    /// Adds a keyboard toolbar button that dismisses the keyboard by clearing `isFocused`.
    /// Pass the projected value of a `@FocusState`: `.dismissKeyboardButton(isFocused: $isFocused)`.
    func dismissKeyboardButton(isFocused: FocusState<Bool>.Binding, label: String = "Dismiss") -> some View {
        modifier(DismissKeyboardButtonModifier(isFocused: isFocused, label: label))
    }
}
