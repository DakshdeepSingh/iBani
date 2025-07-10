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
        BaniDataModel.shared.preloadAllBanis()
    }
    var body: some Scene {
        WindowGroup {
            CategorySelectionView()
                .environmentObject(appSettings)
        }
    }
}
