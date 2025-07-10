//
//  AppSettings.swift
//  iBanis
//
//  Created by Dakshdeep Singh on 05/07/25.
//


import SwiftUI

class AppSettings: ObservableObject {
    @Published var tintColor: Color = .white

    // You can add methods to change the tint color if needed
    func setTintColor(_ color: Color) {
        self.tintColor = color
    }
}
