//
//  OrchardEyeApp.swift
//  OrchardEye
//
//  Dual-sensor crop disease & quality scanner (Congressional App Challenge, WA-08).
//

import SwiftUI

@main
struct OrchardEyeApp: App {
    @StateObject private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .environmentObject(app.store)
        }
    }
}
