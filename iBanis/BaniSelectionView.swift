//
//  BaniSelectionView.swift
//  iBanis
//
//  Created by Brahmjot Singh Tatla on 05/04/25.
//

import SwiftUI

struct BaniSelectionView: View {
    let selectedCategory: BaniCategory
    @EnvironmentObject var appSettings: AppSettings

    var filteredBaniTypes: [BaniType] {
        BaniType.allCases.filter { $0.category == selectedCategory }
    }

    var body: some View {
        List {
            ForEach(filteredBaniTypes) { type in
                NavigationLink(destination: BaniView(baniType: type)) {
                    Text(type.displayTitle)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.vertical, 6)
                }
                .listRowBackground(Color(UIColor.systemBackground))
            }
            Section {
                Text("Bani data powered by Khalis Foundation via BaniDB API")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
            }
            .listRowBackground(Color(UIColor.systemBackground))
        }
        .listStyle(.plain)
        .background(Color(UIColor.systemBackground))
        .navigationTitle(selectedCategory.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                        .tint(.white)
                }
            }
        }
        .onAppear {
            appSettings.setTintColor(.white)
        }
    }
}

#Preview {
    BaniSelectionView(selectedCategory: .nitnem)
}
