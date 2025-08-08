//
//  iBanisApp.swift
//  iBanis
//
//  Created by Brahmjot Singh Tatla on 25/03/25.
//

import SwiftUI

@main
struct iBanisApp: App {
    @StateObject private var appSettings = AppSettings()

    init() {
        // Preload all banis from local cache
        BaniDataModel.shared.preloadAllBanis()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                CategorySelectionView()
            }
            .environmentObject(appSettings)
        }
    }
}
