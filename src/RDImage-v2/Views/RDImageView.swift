//
//  RDImageView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/14/26.
//

import Kingfisher
import SwiftUI

struct RDImageView: View {
    let url: URL?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let url, !loadFailed {
                KFImage(url)
                    .placeholder { RDImagePlaceholder(content: .loading) }
                    .onFailure { _ in loadFailed = true }
                    .fade(duration: 0.2)
                    .resizable()
                    .scaledToFill()
            } else {
                RDImagePlaceholder(content: loadFailed ? .error : .empty())
            }
        }
    }
}
