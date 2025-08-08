//
//  CategorySelectionView.swift
//  iBanis
//
//  Created by Brahmjot Singh Tatla on 02/07/25.
//

import SwiftUI

struct CategorySelectionView: View {
    @EnvironmentObject var appSettings: AppSettings

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.blue
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationStack {
            Group {
                if appSettings.isPad {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(BaniCategory.allCases, id: \.self) { category in
                                SectionView(category: category)
                            }
                        }
                        .padding(.top, 20)
                    }
                } else {
                    List {
                        ForEach(BaniCategory.allCases, id: \.self) { category in
                            Section(header: Text(category.rawValue).font(.headline)) {
                                ForEach(BaniType.allCases.filter { $0.category == category }) { bani in
                                    NavigationLink(destination: destinationView(for: bani)) {
                                        Text(bani.displayTitle)
                                            .padding(.vertical, 6)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("iBanis")
            .navigationBarTitleDisplayMode(.large)
        }
        .tint(appSettings.tintColor)
    }

    // MARK: - iPad Grid Section
    @ViewBuilder
    func SectionView(category: BaniCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.rawValue)
                .font(.title2.bold())
                .padding(.horizontal)

            let filteredBanis = BaniType.allCases.filter { $0.category == category }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 16)], spacing: 16) {
                ForEach(filteredBanis) { bani in
                    NavigationLink(destination: destinationView(for: bani)) {
                        Text(bani.displayTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .background(Color.blue)
                            .cornerRadius(14)
                            .shadow(radius: 3)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Route BaniType to the correct destination
    @ViewBuilder
    func destinationView(for bani: BaniType) -> some View {
        switch bani {
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
            BaniView(baniType: bani)
        }
    }

    func loadBundledPDF(named name: String) -> URL? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "pdf") else {
            print("❌ PDF not found: \(name)")
            return nil
        }
        return url
    }
}

#Preview {
    CategorySelectionView()
        .environmentObject(AppSettings())
}
