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

enum SmallCTASize {
    case `default`
    case small

    var textFont: Font {
        switch self {
        case .default:
            return .caption
        case .small:
            return .caption2
        }
    }

    var iconFont: Font {
        switch self {
        case .default:
            return .caption2.bold()
        case .small:
            return .system(size: 8).bold()
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .default:
            return 12
        case .small:
            return 8
        }
    }

    var topPadding: CGFloat {
        switch self {
        case .default:
            return 8
        case .small:
            return 5
        }
    }

    var bottomPadding: CGFloat {
        switch self {
        case .default:
            return 7
        case .small:
            return 4
        }
    }
}

struct SmallCTA: View {
    @Environment(\.isEnabled) private var isEnabled
    var isButton: Bool = true

    let type: SmallCTAType
    var size: SmallCTASize = .default

    var leadingIcon: String?
    var leadingIconColor: Color?
    var trailingIcon: String?

    var text: String = ""
    var textColor: Color?

    var buttonColor: Color?

    var fullWidth: Bool = false
    var semibold: Bool = true
    var isLoading: Bool = false
    var action: () -> Void = {}
    
    init(
        isButton: Bool = true,
        type: SmallCTAType,
        size: SmallCTASize = .default,
        leadingIcon: String? = nil,
        leadingIconColor: Color? = nil,
        trailingIcon: String? = nil,
        text: String = "",
        textColor: Color? = nil,
        buttonColor: Color? = nil,
        fullWidth: Bool = false,
        semibold: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void = {}
    ) {
        self.isButton = isButton
        self.type = type
        self.size = size
        self.leadingIcon = leadingIcon
        self.leadingIconColor = leadingIconColor
        self.trailingIcon = trailingIcon
        self.text = text
        self.textColor = textColor
        self.buttonColor = buttonColor
        self.fullWidth = fullWidth
        self.semibold = semibold
        self.isLoading = isLoading
        self.action = action
    }
    

    var body: some View {
        if isButton {
            Button(action: action) {
                SmallCTAView()
            }
            .allowsHitTesting(!isLoading)
        } else {
            SmallCTAView()
        }
    }

    @ViewBuilder
    private func SmallCTAView() -> some View {
        HStack(spacing: 4) {
            if isLoading {
                ProgressView()
                    .controlSize(.mini)
                    .tint(leadingIconColor ?? textColor ?? type.foregroundColor)
            } else if let leadingIcon {
                Image(systemName: leadingIcon)
                    .foregroundStyle(leadingIconColor ?? textColor ?? type.foregroundColor)
                    .font(size.iconFont)
            }

            if text != "" {
                Text(text)
                    .font(size.textFont)
                    .if(semibold) { view in
                        view.fontWeight(.semibold)
                    }
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor ?? type.foregroundColor)
                    .if(fullWidth) { view in
                        view.frame(maxWidth: .infinity)
                    }
            }
            
            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .foregroundStyle(textColor ?? type.foregroundColor)
                    .font(size.iconFont)
            }
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.top, size.topPadding)
        .padding(.bottom, size.bottomPadding)
        .background(buttonColor ?? type.buttonColor)
        .overlay(
            Capsule()
                .stroke(type.borderColor ?? Color.clear, lineWidth: type.borderWidth)
        )
        .clipShape(.capsule)
        .opacity(isEnabled ? 1.0 : 0.5)
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
        SmallCTA(type: .secondary, size: .small, leadingIcon: "plus", text: "Small", action: {})
        SmallCTA(type: .outline, size: .small, leadingIcon: "plus", text: "Loading", isLoading: true, action: {})
    }
    .padding()
}
