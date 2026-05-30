//
//  SearchBar.swift
//  RedDoor
//
//  Created by Quinn Liu
//

import SwiftUI

struct SearchBarComponent: View {
    @Binding var searchText: String
    @Binding var searchFocused: Bool
    @FocusState.Binding var searchTextFocused: Bool
    
    var onSubmit: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: SFSymbols.magnifyingglass)
                    .bold()
                    .foregroundColor(.red)
                
                TextField("", text: $searchText, prompt: Text("Search..."))
                    .submitLabel(.search)
                    .focused($searchTextFocused)
                    .onSubmit {
                        if !searchText.isEmpty {
                            onSubmit?()
                        }
                    }
            }
            .padding(8)
            .clipShape(.rect(cornerRadius: 8))
            
            if searchFocused {
                Button("Cancel", role: .destructive) {
                    searchText = ""
                    onCancel?()
                    searchTextFocused = false
                    searchFocused = false
                }
            }
        }
    }
}

#Preview {
    @Previewable @FocusState var searchTextFocused: Bool
    
    VStack {
        SearchBarComponent(
            searchText: .constant(""),
            searchFocused: .constant(false),
            searchTextFocused: $searchTextFocused
        )
    }
    .padding()
}

