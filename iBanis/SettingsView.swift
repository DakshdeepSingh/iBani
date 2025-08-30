//
//  SettingsView.swift
//  iBanis
//
//  Created by Brahmjot Singh Tatla on 02/07/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("showTranslation") private var showTranslation = true
    @AppStorage("showEnglishTranslation") private var showEnglishTranslation = true
    @AppStorage("showHindiTranslation") private var showHindiTranslation = false
    @AppStorage("fontSize") private var fontSize: Double = 22
    @EnvironmentObject var appSettings: AppSettings

    var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        Form {
            Section(header: Text("Display")) {
                Toggle("Show Translation", isOn: $showTranslation)
                    .tint(.green)

                Toggle("Show English Translation", isOn: $showEnglishTranslation)
                    .tint(.green)
                    .disabled(!showTranslation)
                Toggle("Show Hindi Translation", isOn: $showHindiTranslation)
                    .tint(.green)
                    .disabled(!showTranslation)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Font Size: \(Int(fontSize))")
                        .font(.caption)

                    Slider(value: $fontSize, in: 18...36, step: 1)
                        .tint(.blue)

                    Text("ੳਅੲ")
                        .font(.custom("GurbaniAkharHeavy", size: CGFloat(fontSize)))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                        .padding(.top, 4)
                }
                .padding(.horizontal, isPad ? 24 : 0)
                .onAppear {
                    appSettings.setTintColor(.white)
                }
                .onChange(of: fontSize) { newValue in
                    appSettings.fontSize = CGFloat(newValue)
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
    NavigationStack {
        SettingsView()
            .environmentObject(AppSettings())
    }
}
