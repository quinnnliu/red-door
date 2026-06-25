//
//  SearchBarV2.swift
//  RedDoor
//
//  Created by Quinn Liu
//

import SwiftUI

struct SearchBarV2: View {
    @Binding var isActive: Bool
    @State private var searchText: String = ""
    @FocusState private var isFocused: Bool

    private let action: (Any) -> Void

    init(isActive: Binding<Bool>, action: @escaping (Any) -> Void = { _ in }) {
        self._isActive = isActive
        self.action = action
    }

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .bold()
                    .foregroundColor(.red)

                TextField("", text: $searchText, prompt: Text("Search..."))
                    .submitLabel(.search)
                    .focused($isFocused)
                    .onSubmit {
                        guard !searchText.isEmpty else { return }
                        action(SearchBarAction.search(text: searchText))
                        isFocused = false
                    }
            }
            .padding(8)
            .clipShape(.rect(cornerRadius: 8))
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isFocused)

            Button("Cancel", role: .destructive) {
                searchText = ""
                action(SearchBarAction.cancel)
                isFocused = false
                isActive = false
            }
        }
        .onAppear { isFocused = true }
    }
}

enum SearchBarAction {
    case search(text: String)
    case cancel
}
