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
        // Customize navigation bar with blue background and white text
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
            List {
                ForEach(BaniCategory.allCases, id: \.self) { category in
                    NavigationLink(destination: BaniSelectionView(selectedCategory: category)) {
                        Text(category.rawValue)
                            .font(.body)
                            .foregroundColor(.black)
                            .padding(.vertical, 8)
                    }
                    .listRowBackground(Color.white)
                }


            }
            .listStyle(.plain)
            .navigationTitle("iBanis")
            .navigationBarTitleDisplayMode(.large) // ✅ Large title
        }
        .tint(appSettings.tintColor)
    }
}

#Preview {
    CategorySelectionView()
        .environmentObject(AppSettings())
}
