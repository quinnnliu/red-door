//
//  RDButton.swift
//  RedDoor
//
//  Created by Quinn Liu
//

import SwiftUI

enum RDButtonVariant {
    case `default`
    case destructive
    case outline
    case secondary
    case ghost
    case link
    case red
    
    var backgroundColor: Color {
        switch self {
        case .default:
            return Color.secondary
        case .destructive, .red:
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
            return .white
        case .destructive, .red:
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

enum RDButtonSize {
    case sm
    case `default`
    case lg
    case icon
    
    var horizontalPadding: CGFloat {
        switch self {
        case .sm:
            return 12
        case .default:
            return 16
        case .lg:
            return 32
        case .icon:
            return 8
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .sm:
            return 6
        case .default:
            return 10
        case .lg:
            return 12
        case .icon:
            return 8
        }
    }
    
    var fontSize: Font {
        switch self {
        case .sm:
            return .caption
        case .default:
            return .body
        case .lg:
            return .body
        case .icon:
            return .body
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .sm:
            return 14
        case .default:
            return 16
        case .lg:
            return 18
        case .icon:
            return 14
        }
    }
    
    var fixedIconButtonSize: CGFloat? {
        switch self {
        case .icon:
            return 32
        default:
            return nil
        }
    }
}

struct RDButton: View {
    let variant: RDButtonVariant
    var size: RDButtonSize = .default
    var leadingIcon: String? = nil
    var trailingIcon: String? = nil
    var iconBold: Bool = false
    var label: String? = nil
    var fullWidth: Bool = false
    var disabled: Bool = false
    var allowsHitTesting: Bool = true
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: size == .icon ? 0 : 8) {
                if let leadingIcon {
                    Image(systemName: leadingIcon)
                        .font(.system(size: size.iconSize))
                        .fontWeight(iconBold ? .bold : .medium)
                }
                
                if let label, size != .icon {
                    Text(label)
                        .font(size.fontSize)
                        .fontWeight(.medium)
                }
                
                if let trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.system(size: size.iconSize))
                }
            }
            .foregroundStyle(disabled ? Color.gray : variant.foregroundColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(
                width: size == .icon ? size.fixedIconButtonSize : nil,
                height: size == .icon ? size.fixedIconButtonSize : nil,
                alignment: .center
            )
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(disabled ? Color.gray.opacity(0.2) : variant.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(variant.borderColor ?? Color.clear, lineWidth: variant.borderWidth)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(disabled ? 0.5 : 1.0)
        }
        .allowsHitTesting(allowsHitTesting)
        .disabled(disabled)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !disabled {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// Link variant with underline
struct RDLinkButton: View {
    var text: String?
    var leadingIcon: String?
    var size: RDButtonSize = .default
    var disabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: size == .icon ? 0 : 8) {
                if let leadingIcon {
                    Image(systemName: leadingIcon)
                        .font(.system(size: size.iconSize))
                        .fontWeight(.medium)
                        .foregroundStyle(disabled ? Color.gray : Color.primary)
                }
                
                if let buttonText = text {
                    Text(buttonText)
                        .font(size.fontSize)
                        .fontWeight(.medium)
                        .foregroundStyle(disabled ? Color.gray : Color.primary)
                        .underline()
                }
            }
        }
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
    }
}

#Preview {
    VStack(spacing: 16) {
        // Default variants
        VStack(spacing: 12) {
            RDButton(variant: .default, label: "Default", action: {})
            RDButton(variant: .destructive, label: "Destructive", action: {})
            RDButton(variant: .outline, label: "Outline", action: {})
            RDButton(variant: .secondary, label: "Secondary", action: {})
            RDButton(variant: .ghost, label: "Ghost", action: {})
            RDLinkButton(text: "Link Button", action: {})
        }
        
        // Sizes
        VStack(spacing: 12) {
            RDButton(variant: .default, size: .sm, label: "Small", action: {})
            RDButton(variant: .default, size: .default, label: "Default", action: {})
            RDButton(variant: .default, size: .lg, label: "Large", action: {})
            RDButton(variant: .default, size: .icon, leadingIcon: "plus", action: {})
        }
        
        // With icons
        VStack(spacing: 12) {
            RDButton(variant: .default, leadingIcon: "plus", label: "Add Item", action: {})
            RDButton(variant: .outline, trailingIcon: "arrow.right", label: "Continue", action: {})
        }
        
        // Full width
        RDButton(variant: .default, label: "Full Width Button", fullWidth: true, action: {})
        
        // Disabled
        RDButton(variant: .default, label: "Disabled", disabled: true, action: {})
    }
    .padding()
}

