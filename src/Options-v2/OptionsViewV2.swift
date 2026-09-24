//
//  OptionsViewV2.swift
//  RedDoor
//
//  Created by Quinn Liu on 6/7/26.
//

import SwiftUI

struct OptionsViewV2: View {
    @Environment(NavigationCoordinator.self) var coordinator

    @State private var showProfileSheet: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            TopBar()

            WarehouseOptionView()

            Spacer()

            Link("Suggest a Feature", destination: URL(string: "https://docs.google.com/document/d/19aw0hf8dCUa8ycFY7alWmv5hmq79pkwnndopVsu-IEE/edit?usp=sharing")!)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray5))
                .cornerRadius(8)
                .bold()
                .foregroundColor(.red)

        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .toolbar(.hidden)
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheet()
        }
    }

        // MARK: Top Bar
    @ViewBuilder
    private func TopBar() -> some View {
        TopAppBar(leadingView: {
            Text("Options")
                .font(.system(.title2, design: .default))
                .foregroundColor(.red)
                .bold()
        }, header: {
            EmptyView()
        }, trailingView: {
            ProfileImage()
        })
    }

        // MARK: Profile Image
    @ViewBuilder
    private func ProfileImage() -> some View {
        Button {
            showProfileSheet = true
        } label: {
            Image(systemName: SFSymbols.personCircle)
                .foregroundColor(.red)
                .font(.system(size: 24))
        }
    }

        // MARK: Profile Sheet
    @ViewBuilder
    private func ProfileSheet() -> some View {
        VStack(spacing: 12) {
            Text("Profile Section")
                .font(.headline)
                .foregroundColor(.primary)

            Text("You currently can't sign in with an account. But this section will be available in the future 🙂")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    OptionsView()
}
