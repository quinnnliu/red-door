//
//  RedDoorApp.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/6/24.
//

import FirebaseCore
import FirebaseFirestore
import Kingfisher
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
    {
        return true
    }
}

@main
struct RedDoorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var isReady = false

    init() {
        FirebaseApp.configure()
        UITabBar.appearance().tintColor = UIColor.red
        configureImageCache()
    }

    private func configureImageCache() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024  // 50 MB
        cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024         // 200 MB
        cache.diskStorage.config.expiration = .never
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                if isReady {
                    ContentView()
                } else {
                    Image("RedDoor")
                        .resizable()
                        .scaledToFit()
                        .frame(Constants.Screen.screenWidth / 4)
                        .task {
                            await ConfigurationService.shared.preload()
                            isReady = true
                        }
                }
            }
        }
    }
}
