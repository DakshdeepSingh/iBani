//
//  AppSettings.swift
//  iBanis
//
//  Created by Dakshdeep Singh on 05/07/25.
//

import SwiftUI

class AppSettings: ObservableObject {
    @Published var tintColor: Color = .white

    // Auto-adjusted font size based on device type
    @Published var fontSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 26 : 22

    // iPad detection flag (can be used in views for layout changes)
    var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    // Method to change the tint color
    func setTintColor(_ color: Color) {
        self.tintColor = color
    }
}
