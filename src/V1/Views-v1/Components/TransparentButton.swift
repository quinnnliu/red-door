//
//  TransparentButton.swift
//  RedDoor
//
//  Created by Quinn Liu on 12/20/24.
//

import SwiftUI

struct TransparentButton: View {
    var backgroundColor: Color
    var foregroundColor: Color

    var isButton: Bool = true

    var leadingIcon: String?

    let text: String
    var textColor: Color?

    var fullWidth: Bool = false
    var alignment: Alignment = .center
    var bold: Bool = false
    let action: () -> Void

    var body: some View {
        if isButton {
            Button(action: action) {
                TransparentButtonView()
            }
        } else {
            TransparentButtonView()
        }
    }

    @ViewBuilder
    private func TransparentButtonView() -> some View {
        HStack {
            HStack(spacing: 8) {
                if let leadingIcon {
                    Image(systemName: leadingIcon)
                        .foregroundStyle(foregroundColor)
                        .frame(maxWidth: 16, maxHeight: 16)
                }

                Text(text)
                    .foregroundStyle(foregroundColor)
            }
            .if(bold) { view in
                view.fontWeight(.bold)
            }
            .if(fullWidth) { view in
                view.frame(maxWidth: .infinity, alignment: alignment)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor.opacity(0.2))
        .cornerRadius(8)
        .frame(maxWidth: .infinity)
    }

    //    func body(content: Content) -> some View {
    //        content
    //            .padding(.horizontal, 16)
    //            .padding(.vertical, 12)
    //            .background(backgroundColor.opacity(0.2))
    //            .foregroundColor(foregroundColor)
    //            .clipShape(.capsule)
    //            .if(fullWidth) { view in
    //                view.frame(maxWidth: .infinity)
    //            }
    //    }
}

// extension View {
//    func transparentButton(backgroundColor: Color, foregroundColor: Color, fullWidth: Bool = false) -> some View {
//        self.modifier(TransparentButton(backgroundColor: backgroundColor, foregroundColor: foregroundColor, fullWidth: fullWidth))
//    }
// }
