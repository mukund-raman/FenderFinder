//
//  FenderFinderAppApp.swift
//  FenderFinderApp
//
//  Created by Adarsh Goura on 11/4/23.
//

import SwiftUI

@main
struct FenderFinderAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func applicationDidEnterBackground(_ application: UIApplication) {
        LocationService.shared.stopUpdatingLocation()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        LocationService.shared.startUpdatingLocation()
    }
    
    // Implement other app delegate methods as needed
}
