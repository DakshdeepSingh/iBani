//
//  SettingsView.swift
//  iBanis
//
//  Created by Brahmjot Singh Tatla on 02/07/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("showTranslation") private var showTranslation = true
    @AppStorage("fontSize") private var fontSize: Double = 22
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        Form {
            Section(header: Text("Display")) {
                Toggle("Show Translation", isOn: $showTranslation)
                    .tint(.green)

                VStack(alignment: .leading) {
                    Text("Font Size: \(Int(fontSize))")
                        .font(.caption)
                    Slider(value: $fontSize, in: 18...36, step: 1)
                        .tint(.blue)
                    Text("ੳਅੲ")
                        .font(.system(size: CGFloat(fontSize)))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                        .padding(.top, 8)
                }
                .onAppear {
                    appSettings.setTintColor(.white)
                }
            }

            Section {
                Button(action: {
                    if let url = URL(string: "https://ibani-about-page.vercel.app/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("About iBani", systemImage: "info.circle")
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
