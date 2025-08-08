//
//  BaniView.swift
//  iBanis
//
//  Created by Brahmjot Singh Tatla on 25/03/25.
//

import SwiftUI
import Foundation

struct BaniView: View {
    let baniType: BaniType
    @ObservedObject var model = BaniDataModel.shared
    @EnvironmentObject var appSettings: AppSettings

    @AppStorage("showTranslation") private var showTranslation = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                ScrollView {
                    content
                        .padding(.horizontal, appSettings.isPad ? 40 : 16)
                        .padding(.vertical, 10)
                }
            }
            .navigationTitle(baniType.displayTitle)
            .toolbarBackground(Color.blue, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .onAppear {
                model.fetchBani(for: baniType)
                appSettings.setTintColor(.blue)
            }
            .onDisappear {
                BaniDataModel.shared.currentBani = nil
            }
        }
    }

    // MARK: - Dynamic Content Rendering
    private var content: some View {
        Group {
            if let bani = model.currentBani {
                LazyVStack(alignment: .center, spacing: 20) {
                    ForEach(bani.lines) { line in
                        if !line.line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(spacing: 6) {
                                HighlightedText(line: line.line, fontSize: appSettings.fontSize)
                                    .multilineTextAlignment(.center)

                                if showTranslation,
                                   let translation = line.translation,
                                   !translation.isEmpty {
                                    Text(translation)
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            } else if let error = modelError {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                ProgressView("Loading Bani...")
                    .padding()
            }
        }
    }

    var modelError: String? {
        return nil
    }
}

// MARK: - Highlighted Gurbani Line View

struct HighlightedText: View {
    let line: String
    let fontSize: CGFloat

    var body: some View {
        Text(makeAttributedString(from: line))
            .font(.custom("GurbaniAkharHeavy", size: fontSize, relativeTo: .body))
            .lineSpacing(10)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.8)
    }

    private func makeAttributedString(from line: String) -> AttributedString {
        var attrString = AttributedString(line)
        applyHighlights(to: &attrString)
        return attrString
    }

    private func applyHighlights(to attrString: inout AttributedString) {
        let greenWords: [String] = ["ਸਤਿਨਾਮੁ", "ਪੁਰਖੁ", "ਮੂਰਤਿ", "ਸੈਭੰ", "ਸੋਚੈ", "ਚੁਪੈ", "ਭੁਖਿਆ", "ਕਿਵ", "ਨਾਨਕ", "ਹੁਕਮੀ", "ਜੀਅ", "ਲਿਖਿ"]
        let orangeWords: [String] = ["ੴ", "ਨਿਰਵੈਰੁ", "ਨਿਰਭਉ", "ਸਚੁ", "ਹੋਵਈ", "ਚਲਣਾ", "ਆਕਾਰ", "ਉਤਮੁ", "ਨੀਚੁ", "ਦੁਖ", "ਸੁਖ", "ਬਖਸੀਸ", "ਰਜਾਈ"]

        for word in greenWords {
            highlight(word: word, color: .green, in: &attrString)
        }

        for word in orangeWords {
            highlight(word: word, color: .orange, in: &attrString)
        }
    }

    private func highlight(word: String, color: Color, in attrString: inout AttributedString) {
        var searchRange = attrString.startIndex..<attrString.endIndex
        while let range = attrString[searchRange].range(of: word) {
            attrString[range].foregroundColor = color
            searchRange = range.upperBound..<attrString.endIndex
        }
    }
}

#Preview {
    NavigationStack {
        BaniView(baniType: .japjiSahib)
            .environmentObject(AppSettings())
    }
}
