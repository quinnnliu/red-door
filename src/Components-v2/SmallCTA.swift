//
//  SmallCTA.swift
//  RedDoor
//
//  Created by Quinn Liu on 3/27/25.
//

import SwiftUI

enum SmallCTAType {
    case `default`
    case red
    case outline
    case secondary
    case ghost
    case link

    var buttonColor: Color {
        switch self {
        case .default:
            return Color.primary
        case .red:
            return Color(.red)
        case .outline:
            return Color.clear
        case .secondary:
            return Color(.systemGray5)
        case .ghost:
            return Color.clear
        case .link:
            return Color.clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .default:
            return Color(.systemBackground)
        case .red:
            return .white
        case .outline:
            return Color.primary
        case .secondary:
            return Color.primary
        case .ghost:
            return Color.primary
        case .link:
            return Color.primary
        }
    }
    
    var borderColor: Color? {
        switch self {
        case .outline:
            return Color(.separator)
        default:
            return nil
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .outline:
            return 1
        default:
            return 0
        }
    }
}

struct SmallCTA: View {
    var isButton: Bool = true

    let type: SmallCTAType

    var leadingIcon: String?
    var leadingIconColor: Color?

    var text: String = ""
    var textColor: Color?

    var buttonColor: Color?

    var semibold: Bool = true
    var action: () -> Void = {}

    var body: some View {
        if isButton {
            Button(action: action) {
                SmallCTAView()
            }
        } else {
            SmallCTAView()
        }
    }

    @ViewBuilder
    private func SmallCTAView() -> some View {
        HStack(spacing: 0) {
            if let leadingIcon {
                Image(systemName: leadingIcon)
                    .foregroundStyle(leadingIconColor ?? textColor ?? type.foregroundColor)
                    .font(.caption.bold())
                    .padding(.trailing, 4)
            }

            if text != "" {
                Text(text)
                    .font(.caption)
                    .if(semibold) { view in
                        view.fontWeight(.semibold)
                    }
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor ?? type.foregroundColor)
                    .if(leadingIcon == nil) { view in
                        view.frame(maxWidth: .infinity)
                    }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 7)
        .background(buttonColor ?? type.buttonColor)
        .overlay(
            Capsule()
                .stroke(type.borderColor ?? Color.clear, lineWidth: type.borderWidth)
        )
        .clipShape(.capsule)
    }
}

#Preview {
    VStack(spacing: 12) {
        SmallCTA(type: .default, leadingIcon: "plus", text: "Default", action: {})
        SmallCTA(type: .red, leadingIcon: "trash", text: "Destructive", action: {})
        SmallCTA(type: .outline, leadingIcon: "plus", text: "Outline", action: {})
        SmallCTA(type: .secondary, leadingIcon: "plus", text: "Secondary", action: {})
        SmallCTA(type: .ghost, leadingIcon: "plus", text: "Ghost", action: {})
        SmallCTA(type: .secondary, leadingIcon: "plus", text: "Custom Color", buttonColor: .blue, action: {})
        SmallCTA(type: .secondary, leadingIcon: "plus", text: "Not Semibold", semibold: false, action: {})
        SmallCTA(type: .secondary, leadingIcon: "checkmark", leadingIconColor: .green, text: "Custom Icon Color", action: {})
    }
    .padding()
}
