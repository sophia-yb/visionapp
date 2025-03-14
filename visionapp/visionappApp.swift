//
//  visionappApp.swift
//  visionapp
//
//  Created by Sophia Buda on 1/17/25.
//

import SwiftUI

@main
struct visionappApp: App {
    @MainActor @StateObject private var visionProcessor  = VisionProcessor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(visionProcessor)
        }
    }
}
