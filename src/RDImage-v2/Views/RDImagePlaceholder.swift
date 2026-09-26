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
    let size: CGFloat
    
    init(content: Content, size: CGFloat = Constants.Screen.screenWidth / 2) {
        self.content = content
        self.size = size
    }

    var body: some View {
        Color(.systemGray6)
            .overlay {
                switch content {
                case .loading:
                    ProgressView()
                case .empty(let editable):
                    if editable {
                        Image(systemName: SFSymbols.photoBadgePlus)
                            .frame(size)
                            .bold()
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: SFSymbols.photoBadgeExclamationmarkFill)
                            .frame(size)
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
