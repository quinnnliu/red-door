//
//  RedDoorApp.swift
//  RedDoor
//
//  Created by Quinn Liu on 8/6/24.
//

import FirebaseCore
import FirebaseFirestore
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
    @State private var configurationService = ConfigurationService()
    @State private var isReady = false

    init() {
        FirebaseApp.configure()
        UITabBar.appearance().tintColor = UIColor.red
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                if isReady {
                    ContentView()
                        .environment(configurationService)
                } else {
                    ProgressView("Loading...")
                        .task {
                            await configurationService.preload()
                            isReady = true
                        }
                }
            }
        }
    }
}
