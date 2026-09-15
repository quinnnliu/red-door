//
//  RDImagePlaceholder.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/14/26.
//

import SwiftUI

struct RDImagePlaceholder: View {
    enum Content {
        case loading
        case empty(editable: Bool = false)
        case error
    }

    let content: Content

    var body: some View {
        Color(.systemGray5)
            .overlay {
                switch content {
                case .loading:
                    ProgressView()
                case .empty(let editable):
                    if editable {
                        Image(systemName: SFSymbols.photoBadgePlus)
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(.secondary)
                    }
                case .error:
                    Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                        .foregroundStyle(.secondary)
                }
            }
    }
}
