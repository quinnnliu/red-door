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
    func makeUIViewController(context: Context) -> SwipeBackViewController { SwipeBackViewController() }
    func updateUIViewController(_ vc: SwipeBackViewController, context: Context) {}

    class SwipeBackViewController: UIViewController {
        private let swipeDelegate = SwipeDelegate()

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            guard let nav = navigationController else { return }
            swipeDelegate.navigationController = nav
            nav.interactivePopGestureRecognizer?.isEnabled = true
            nav.interactivePopGestureRecognizer?.delegate = swipeDelegate
        }
    }

    class SwipeDelegate: NSObject, UIGestureRecognizerDelegate {
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
                        ItemViewFactory().makeItemDetailsView(item: item)
                    case .pullListDetailView(let list):
                        PullListViewFactory().makeDetailsView(list: list)
                    case .pulllistRoomDetailView(let items, let room):
                        PullListRoomDetailsView(items: items, room: room)
                    case .pullListItemDetailView(let item, let room):
                        PullListItemDetailsView(item: item, room: room)
                    case .installedListItemDetailView(let item, let room, let uninstalled):
                        InstalledListViewFactory().makeItemDetailsView(item: item, room: room, uninstalled: uninstalled)
                    case .addItemToRoomDetailView(let item, let room):
                        AddItemToRoomDetailView(item: item, room: room)
                    case .installedListDetailView(let list):
                        InstalledListViewFactory().makeDetailsView(list: list)
                    case .installedListRoomDetailView(let items, let room, let uninstalled):
                        InstalledListViewFactory().makeRoomDetailsView(items: items, room: room, uninstalled: uninstalled)
                    case .essentialsGroupDetailView(let group):
                        EssentialsGroupDetailView(group: group)
                    case .accessoriesDetailView(let accessories):
                        AccessoriesDetailsView(accessories: accessories)
                    case .addItemToDocumentDetailView(let item, let destination):
                        AddItemToDocumentDetailView(item: item, destination: destination)
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
