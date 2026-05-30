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

    var path: Binding<NavigationPath>? = nil

    var body: some View {
        RDButton(variant: .red, size: .icon, leadingIcon: "chevron.left", iconBold: true, fullWidth: false) {
            if path != nil {
                self.path?.wrappedValue = NavigationPath()
            } else {
                dismiss()
            }
        }
        .clipShape(Circle())
    }
}
