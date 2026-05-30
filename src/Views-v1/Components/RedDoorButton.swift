//
//  RedDoorButton.swift
//  RedDoor
//
//  Created by Quinn Liu on 1/16/25.
//

import SwiftUI

enum RedDoorButtonType {
    case green
    case red
    case blue
    case gray

    var buttonColor: Color {
        switch self {
        case .green: .green
        case .red: .red
        case .blue: .blue
        case .gray: .gray
        }
    }
}

struct RedDoorButton: View {
    var isButton: Bool = true

    let type: RedDoorButtonType

    var leadingIcon: String?
    var leadingIconColor: Color?

    let text: String
    var textColor: Color?

    var buttonColor: Color?

    var fullWidth: Bool = false
    var alignment: Alignment = .center
    var semibold: Bool = false
    let action: () -> Void

    var body: some View {
        if isButton {
            Button(action: action) {
                RedDoorButtonView()
            }
        } else {
            RedDoorButtonView()
        }
    }

    @ViewBuilder
    private func RedDoorButtonView() -> some View {
        HStack {
            HStack(spacing: 8) {
                if let leadingIcon {
                    Image(systemName: leadingIcon)
                        .foregroundStyle(leadingIconColor ?? .white)
                        .frame(maxWidth: 16, maxHeight: 16)
                }

                Text(text)
                    .foregroundStyle(textColor ?? .white)
            }
            .if(semibold) { view in
                view.fontWeight(.semibold)
            }
            .if(fullWidth) { view in
                view.frame(maxWidth: .infinity, alignment: alignment)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(type.buttonColor)
        .cornerRadius(8)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    RedDoorButton(type: .red, leadingIcon: "plus", text: "Button", fullWidth: true, semibold: true, action: {})
}
