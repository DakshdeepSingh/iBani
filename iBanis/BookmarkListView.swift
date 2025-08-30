//
//  BookmarkListView.swift
//  iBanis
//
//  Created by Dakshdeep Singh on 26/07/25.
//

import SwiftUI

// MARK: - Bookmark Model

struct Bookmark: Codable, Identifiable {
    let id: UUID
    let pageNumber: Int
    var title: String
    var granthTitle: String
    let dateCreated: Date

    init(pageNumber: Int, title: String = "", granthTitle: String = "") {
        self.id = UUID()
        self.pageNumber = pageNumber
        self.title = title.isEmpty ? "Page \(pageNumber + 1)" : title
        self.granthTitle = granthTitle
        self.dateCreated = Date()
    }
}

struct BookmarkListView: View {
    @State private var bookmarks: [Bookmark] = []
    @State private var editingBookmark: Bookmark?
    @State private var showingEditAlert: Bool = false
    @State private var editingTitle: String = ""
    @Environment(\.dismiss) private var dismiss

    // Callback to navigate to a specific page
    let onPageSelected: (Int) -> Void

    var body: some View {
        NavigationView {
            VStack {
                if bookmarks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No Bookmarks")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)

                        Text("Pages you bookmark will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(bookmarks.sorted(by: { $0.pageNumber < $1.pageNumber })) { bookmark in
                            BookmarkRowView(
                                bookmark: bookmark,
                                onTap: {
                                    onPageSelected(bookmark.pageNumber)
                                    dismiss()
                                },
                                onEdit: {
                                    editingBookmark = bookmark
                                    editingTitle = bookmark.title
                                    showingEditAlert = true
                                },
                                onDelete: {
                                    removeBookmark(bookmark)
                                }
                            )
                        }
                        .onDelete(perform: deleteBookmarks)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }

                if !bookmarks.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
        }
        .onAppear {
            loadBookmarks()
        }
        .alert("Edit Bookmark", isPresented: $showingEditAlert) {
            TextField("Bookmark title", text: $editingTitle)
            Button("Save") {
                if let bookmark = editingBookmark {
                    updateBookmarkTitle(bookmark, newTitle: editingTitle.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
            .disabled(editingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) { }
        } message: {
            if let bookmark = editingBookmark {
                Text("Edit the title for page \(bookmark.pageNumber + 1)")
            }
        }
    }

    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: "bookmarksWithTitles"),
           let decodedBookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = decodedBookmarks
        } else {
            let oldBookmarks = UserDefaults.standard.array(forKey: "bookmarkedPages") as? [Int] ?? []
            bookmarks = oldBookmarks.map { Bookmark(pageNumber: $0) }
            saveBookmarks()
        }
    }

    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: "bookmarksWithTitles")
        }

        let pageNumbers = bookmarks.map { $0.pageNumber }
        UserDefaults.standard.set(pageNumbers, forKey: "bookmarkedPages")
    }

    private func updateBookmark(_ updatedBookmark: Bookmark) {
        if let index = bookmarks.firstIndex(where: { $0.id == updatedBookmark.id }) {
            bookmarks[index] = updatedBookmark
            saveBookmarks()
        }
    }

    private func updateBookmarkTitle(_ bookmark: Bookmark, newTitle: String) {
        if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            bookmarks[index].title = newTitle
            saveBookmarks()
        }
    }

    private func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks()
    }

    private func deleteBookmarks(offsets: IndexSet) {
        let sortedBookmarks = bookmarks.sorted(by: { $0.pageNumber < $1.pageNumber })
        for index in offsets {
            let bookmarkToRemove = sortedBookmarks[index]
            removeBookmark(bookmarkToRemove)
        }
    }
}

// MARK: - Bookmark Row View

struct BookmarkRowView: View {
    let bookmark: Bookmark
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if !bookmark.granthTitle.isEmpty {
                    Text(bookmark.granthTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text("Page \(bookmark.pageNumber + 1) | \(bookmark.dateCreated, style: .date)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onTap) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Preview

#Preview {
    let mockBookmarks = [
        Bookmark(pageNumber: 0, title: "Introduction", granthTitle: "ਸਰਬਲੋਹ ਗ੍ਰੰਥ"),
        Bookmark(pageNumber: 5, title: "Chapter 1", granthTitle: "ਦਸਮ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ"),
        Bookmark(pageNumber: 12, title: "Important", granthTitle: "ਸ੍ਰੀ ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ"),
    ]

    if let encoded = try? JSONEncoder().encode(mockBookmarks) {
        UserDefaults.standard.set(encoded, forKey: "bookmarksWithTitles")
    }

    return BookmarkListView { pageNumber in
        print("Navigate to page \(pageNumber)")
    }
}
