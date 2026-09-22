//
//  NavigationDestinationModifier-v2.swift
//  RedDoor
//
//  Created by Quinn Liu on 4/25/26.
//

import Foundation
import SwiftUI

// MARK: - EnableSwipeBack

private struct EnableSwipeBack: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }

    func updateUIViewController(_ vc: UIViewController, context: Context) {
        DispatchQueue.main.async {
            guard let nav = vc.navigationController else { return }
            context.coordinator.navigationController = nav
            nav.interactivePopGestureRecognizer?.isEnabled = true
            nav.interactivePopGestureRecognizer?.delegate = context.coordinator
        }
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var navigationController: UINavigationController?

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }
}

// MARK: - NavigationDestinationsModifierV2

struct NavigationDestinationsModifierV2: ViewModifier {
    @Binding var path: NavigationPath

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: NavigationDestination.self) { destination in
                Group {
                    switch destination {
                    case .itemDetailView(let item):
                        ItemDetailsViewV2(item: item)
                    case .pullListDetailView(let list):
                        PullListV2DetailsView(list: list)
                    case .pulllistRoomDetailView(let items, let room):
                        PullListRoomDetailsView(items: items, room: room)
                    case .pullListItemDetailView(let item, let room):
                        PullListItemDetailsView(item: item, room: room)
                    case .addItemToRoomDetailView(let item, let room):
                        AddItemToRoomDetailView(item: item, room: room)
                    case .installedListDetailView(let list):
                        Text(list.displayName)
                    case .essentialsGroupDetailView(let group, let emoji):
                        EssentialsGroupDetailView(group: group, emoji: emoji)
                    case .accessoriesDetailView(let accessories):
                        AccessoriesDetailsView(accessories: accessories)
                    case .addItemToDocumentDetailView(let context):
                        AddItemToDocumentDetailView(context: context)
                    }
                }
                .background(EnableSwipeBack())
            }
    }
}

extension View {
    func rootNavigationDestinationsV2(path: Binding<NavigationPath>) -> some View {
        modifier(NavigationDestinationsModifierV2(path: path))
    }
}
