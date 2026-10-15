//
//  FirebaseEnvironment.swift
//  RedDoor
//
//  Created by Quinn Liu on 10/14/26.
//

#if DEBUG
import FirebaseCore
import Foundation

/// Debug-only switch between the dev and production Firebase projects.
/// Firebase is configured once per launch, so changing the environment takes effect on the next launch.
enum FirebaseEnvironment: String {
    case dev
    case prod

    private static let defaultsKey = "debug_firebase_environment"

    static var selected: FirebaseEnvironment {
        get { UserDefaults.standard.string(forKey: defaultsKey).flatMap(FirebaseEnvironment.init) ?? .dev }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey) }
    }

    private(set) static var active: FirebaseEnvironment = .dev

    var displayName: String {
        switch self {
        case .dev: "Development"
        case .prod: "Production"
        }
    }

    private var plistName: String {
        switch self {
        case .dev: "GoogleService-Info-Dev"
        case .prod: "GoogleService-Info-Prod"
        }
    }

    /// Configures Firebase with the selected environment, falling back to the default plist.
    static func configure() {
        let environment = selected
        guard let path = Bundle.main.path(forResource: environment.plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path)
        else {
            FirebaseApp.configure()
            return
        }
        FirebaseApp.configure(options: options)
        active = environment
    }
}
#endif
