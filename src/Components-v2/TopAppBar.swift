//
//  TopAppBar.swift
//  RedDoor
//
//  Created by Quinn Liu on 2/14/25.
//

import SwiftUI

struct TopAppBar<LeadingView: View, Header: View, TrailingView: View>: View {
    @ViewBuilder var leadingView: LeadingView
    @ViewBuilder var header: Header
    @ViewBuilder var trailingView: TrailingView

    var body: some View {
        ZStack(alignment: .center) {
            HStack(alignment: .center, spacing: 0) {
                leadingView
                
                Spacer()
                
                trailingView
            }
            
            header
                .frame(maxWidth: (Constants.screenWidth * 0.7), alignment: .center)
        }
        
    }
}

struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    let action: (() -> ())?
    
    init(action: (() -> ())? = nil) {
        self.action = action
    }

    var body: some View {
        RDButton(
            variant: .red,
            size: .icon,
            leadingIcon: self.isPresentedModally ? SFSymbols.xmark : SFSymbols.chevronLeft, // TODO: consider the environment variable injection instead of UIKit
            iconBold: true,
            fullWidth: false
        ) {
            if let action = self.action {
                action()
            }
            dismiss()
        }
        .clipShape(Circle())
    }
}

struct EmptyTopBarIconButton: View {
    var body: some View {
        EmptyView().frame(32)
    }
}
