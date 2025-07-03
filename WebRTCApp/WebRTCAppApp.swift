//
//  WebRTCAppApp.swift
//  WebRTCApp
//
//  Created by Madi Sharipov on 03.07.2025.
//

import SwiftUI

@main
struct WebRTCAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
