//
//  AccessoriesDetailsView.swift
//  RedDoor
//
//  Created by Quinn Liu on 9/20/26.
//

import SwiftUI

struct AccessoriesDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationCoordinator.self) private var coordinator
    @State private var accessories: Accessories
    @State private var showEditSheet: Bool = false
    @State private var locationNavigator = LocationNavigator()
    /// `false` when pushed from a list's detail screen, so the location CTA
    /// can't push that same list again.
    private let locationNavigable: Bool

    init(accessories: Accessories, locationNavigable: Bool = true) {
        self._accessories = State(initialValue: accessories)
        self.locationNavigable = locationNavigable
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 6) {
                TopBar
                NicknameEntry
            }
            .frameHorizontalPadding()

            ImageSection

            LocationRow
                .frameHorizontalPadding()

            DescriptionSection
                .frameHorizontalPadding()

            Spacer()
        }
        .toolbar(.hidden)
        .frameTop()        .alert(locationNavigator.alertMessage, isPresented: $locationNavigator.showAlert) {
            Button("OK") { }
        }
        .sheet(isPresented: $showEditSheet) {
            AccessoriesViewFactory().makeEditAccessoriesSheet(
                accessories: accessories,
                onSave: { updated in accessories = updated },
                onDelete: { dismiss() }
            )
        }
    }
}

// MARK: - Top Bar

private extension AccessoriesDetailsView {
    var TopBar: some View {
        TopAppBar(
            leadingView: {
                BackButton()
            },
            header: {
                VStack(alignment: .center, spacing: 2) {
                    Text(accessories.baseName)
                        .font(.headline)
                        .bold()
                }
            },
            trailingView: {
                RDButton(style: .red, size: .icon, leadingIcon: SFSymbols.pencil) {
                    showEditSheet = true
                }
                .clipShape(Circle())
            }
        )
    }
}

// MARK: - Nickname Entry

private extension AccessoriesDetailsView {
    var NicknameEntry: some View {
        Group {
            if let nickname = accessories.nickname, !nickname.isEmpty {
                Text(nickname)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Image Section

private extension AccessoriesDetailsView {
    var ImageSection: some View {
        PrimaryImageView(image: accessories.primaryImage)
    }
}

// MARK: - Location Row

private extension AccessoriesDetailsView {
    var LocationRow: some View {
        HStack {
            Text("Location")
                .bold()
                .foregroundStyle(.red)

            Spacer()

            LocationStatusCTA(
                location: accessories.location,
                isLoading: locationNavigator.isNavigating,
                action: locationNavigable ? handleAction(_:) : nil
            )
        }
    }
}

// MARK: - Actions

private extension AccessoriesDetailsView {
    func handleAction(_ actionArgument: Any?) {
        switch actionArgument {
        case let locationAction as LocationStatusCTAAction:
            switch locationAction {
            case .navigate(let location):
                Task {
                    if let destination = await locationNavigator.destination(for: location) {
                        coordinator.appendToSelectedPath(destination)
                    }
                }
            }
        default:
            return
        }
    }
}

// MARK: - Description Section

private extension AccessoriesDetailsView {
    var DescriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .foregroundStyle(.red)

            Text(accessories.description.isEmpty ? "No description" : accessories.description)
                .foregroundStyle(accessories.description.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                .padding(10)
                .background(Color(.systemGray5))
                .cornerRadius(Constants.CornerRadius.medium)
        }
    }
}
