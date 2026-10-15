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
    #if DEBUG
    @State private var showEnvironmentAlert: Bool = false
    #endif

    var body: some View {
        VStack(spacing: 16) {
            TopBar()

            StorageLocationOptionsView()

            #if DEBUG
            Spacer()
            DebugEnvironmentToggle()
            #endif
        }
        .frameTop()
        .frameHorizontalPadding()
        .frameBottomPadding()
        .toolbar(.hidden)
        .sheet(isPresented: $showProfileSheet) {
            ProfileSheet()
        }
        #if DEBUG
        .alert("Switch to \(targetEnvironment.displayName)?", isPresented: $showEnvironmentAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Switch and Quit", role: targetEnvironment == .prod ? .destructive : nil) {
                FirebaseEnvironment.selected = targetEnvironment
                exit(0)
            }
        } message: {
            Text(targetEnvironment == .prod
                ? "This will point the app at the PRODUCTION database. Changes you make will affect real data. The app will quit; relaunch it to apply."
                : "The app will quit; relaunch it to use the development database.")
        }
        #endif
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

    #if DEBUG
    // MARK: Debug Environment Toggle
    private var targetEnvironment: FirebaseEnvironment {
        FirebaseEnvironment.active == .dev ? .prod : .dev
    }

    @ViewBuilder
    private func DebugEnvironmentToggle() -> some View {
        VStack(spacing: 8) {
            Text("Debug: \(FirebaseEnvironment.active.displayName) database")
                .font(.footnote)
                .foregroundColor(FirebaseEnvironment.active == .prod ? .red : .secondary)

            Button("Switch to \(targetEnvironment.displayName)") {
                showEnvironmentAlert = true
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }
    #endif
}
