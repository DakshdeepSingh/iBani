//
//  BaniSelectionView.swift
//  iBanis
//
//  Created by Brahmjot Singh Tatla on 05/04/25.
//

import SwiftUI

struct BaniSelectionView: View {
    // Injected in app runtime
    @EnvironmentObject private var appSettings: AppSettings

    // Fallback for preview to avoid crash
    @StateObject private var fallbackSettings = AppSettings()

    // Safe accessor: uses real object if injected, fallback otherwise
    private var safeAppSettings: AppSettings {
        if let value = try? _appSettings.wrappedValue {
            return value
        } else {
            return fallbackSettings
        }
    }

    let selectedCategory: BaniCategory
    let filteredBanis: [BaniType]

    init(selectedCategory: BaniCategory) {
        self.selectedCategory = selectedCategory
        self.filteredBanis = BaniType.allCases.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack(spacing: 0) {
            contentView
                .navigationTitle(selectedCategory.rawValue)
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    safeAppSettings.setTintColor(.white)
                }
                .tint(safeAppSettings.tintColor)

            // Footer: Credit text
            Text("Bani data powered by Khalis Foundation via BaniDB API")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
        }
    }

    // MARK: - Dynamic Layout View
    @ViewBuilder
    private var contentView: some View {
        if safeAppSettings.isPad {
            // iPad Grid Layout
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 20)], spacing: 20) {
                    ForEach(filteredBanis, id: \.self) { baniType in
                        NavigationLink(destination: destinationView(for: baniType)) {
                            Text(baniType.displayTitle)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(Color.blue)
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        } else {
            // iPhone List Layout
            List {
                ForEach(filteredBanis, id: \.self) { baniType in
                    NavigationLink(destination: destinationView(for: baniType)) {
                        Text(baniType.displayTitle)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.vertical, 8)
                    }
                    .listRowBackground(Color(UIColor.systemBackground))
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Destination View Router
    @ViewBuilder
    func destinationView(for baniType: BaniType) -> some View {
        switch baniType {
        case .guruGranthSahibJi:
            PDFViewerView(
                pdfURL: loadBundledPDF(named: "Siri Guru Granth Sahib "),
                title: "ਸ੍ਰੀ ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ"
            )
        case .dasamGranth:
            PDFViewerView(
                pdfURL: loadBundledPDF(named: "Dasam Guru Granth Sahib Hazur Sahib"),
                title: "ਦਸਮ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ"
            )
        case .sarblohGranth:
            PDFViewerView(
                pdfURL: loadBundledPDF(named: "sarbloh_granth"),
                title: "ਸਰਬਲੋਹ ਗ੍ਰੰਥ ਜੀ"
            )
        default:
            BaniView(baniType: baniType)
        }
    }

    // MARK: - Helper to load bundled PDFs
    func loadBundledPDF(named name: String) -> URL? {
        return Bundle.main.url(forResource: name, withExtension: "pdf")
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        BaniSelectionView(selectedCategory: .nitnem)
            .environmentObject(AppSettings()) // ✅ Prevents preview crash
    }
}
