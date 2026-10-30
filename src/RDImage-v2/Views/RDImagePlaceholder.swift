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
    
    init(content: Content) {
        self.content = content
    }

    var body: some View {
        Color(.systemGray6)
            .overlay {
                switch content {
                case .loading:
                    ProgressView()
                case .empty(let editable):
                    Image(systemName: editable ? SFSymbols.photoBadgePlus : SFSymbols.photoBadgeExclamationmarkFill)
                        .bold()
                        .tint(.gray)
                case .error:
                    Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                        .foregroundStyle(.secondary)
                }
            }
    }
}
