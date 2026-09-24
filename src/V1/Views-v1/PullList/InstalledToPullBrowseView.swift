//
//  InstalledToPullBrowseView.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/1/25.
//

import SwiftUI

struct InstalledToPullBrowseView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {

            Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
        .frameTop()
        .frameTopPadding()
        .frameHorizontalPadding()
        .toolbar(.hidden)
    }
}

#Preview {
    InstalledToPullBrowseView()
}
