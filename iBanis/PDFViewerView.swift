//
//  PDFViewerView.swift
//  iBanis
//
//  Created by Brahmjot Singh Tatla on 25/07/25.
//

import SwiftUI
import PDFKit

struct PDFViewerView: View {
    let pdfURL: URL?
    let title: String

    @State private var currentPage: Int = 0
    @State private var isBookmarked: Bool = false
    @State private var pdfViewRef: PDFView?
    @State private var totalPages: Int = 0
    @State private var showingBookmarkList: Bool = false
    @State private var showingAddBookmarkAlert: Bool = false
    @State private var newBookmarkTitle: String = ""

    var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        VStack(spacing: 0) {
            if let pdfURL = pdfURL, let document = PDFDocument(url: pdfURL) {
                PDFKitView(document: document, currentPage: $currentPage, pdfViewRef: $pdfViewRef, totalPages: $totalPages)
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)

                HStack {
                    Button(action: goToPreviousPage) {
                        Image(systemName: "arrow.left.circle.fill")
                            .resizable()
                            .frame(width: isPad ? 40 : 30, height: isPad ? 40 : 30)
                            .foregroundColor(currentPage > 0 ? .blue : .gray)
                    }
                    .disabled(currentPage <= 0)

                    Spacer()

                    Text("Page \(currentPage + 1) of \(totalPages)")
                        .font(isPad ? .title3 : .subheadline)
                        .foregroundColor(.gray)

                    Spacer()

                    Button(action: goToNextPage) {
                        Image(systemName: "arrow.right.circle.fill")
                            .resizable()
                            .frame(width: isPad ? 40 : 30, height: isPad ? 40 : 30)
                            .foregroundColor(currentPage < totalPages - 1 ? .blue : .gray)
                    }
                    .disabled(currentPage >= totalPages - 1)
                }
                .padding(.horizontal, isPad ? 40 : 20)
                .padding(.vertical, 12)
            } else {
                Text("Unable to load PDF")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: {
                        if isBookmarked {
                            removeBookmark(for: currentPage)
                        } else {
                            newBookmarkTitle = "Page \(currentPage + 1)"
                            showingAddBookmarkAlert = true
                        }
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    }

                    Button(action: {
                        showingBookmarkList = true
                    }) {
                        Image(systemName: "list.bullet.rectangle")
                    }
                }
            }
        }
        .onAppear {
            checkBookmarkStatus()
        }
        .onChange(of: currentPage) {
            checkBookmarkStatus()
        }
        .sheet(isPresented: $showingBookmarkList, onDismiss: {
            checkBookmarkStatus()
        }) {
            BookmarkListView { selectedPage in
                navigateToPage(selectedPage)
            }
        }
        .alert("Add Bookmark", isPresented: $showingAddBookmarkAlert) {
            TextField("Bookmark title", text: $newBookmarkTitle)
            Button("Add") {
                let bookmark = Bookmark(
                    pageNumber: currentPage,
                    title: newBookmarkTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    granthTitle: title
                )
                addBookmark(bookmark)
            }
            .disabled(newBookmarkTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter a title for this bookmark")
        }
    }

    // MARK: - Navigation Functions

    private func goToPreviousPage() {
        guard currentPage > 0 else { return }
        navigateToPage(currentPage - 1)
    }

    private func goToNextPage() {
        guard currentPage < totalPages - 1 else { return }
        navigateToPage(currentPage + 1)
    }

    private func navigateToPage(_ pageNumber: Int) {
        guard let document = pdfViewRef?.document,
              pageNumber >= 0,
              pageNumber < document.pageCount,
              let targetPage = document.page(at: pageNumber) else { return }

        pdfViewRef?.go(to: targetPage)
        currentPage = pageNumber
    }

    // MARK: - Bookmark Management

    private func checkBookmarkStatus() {
        let bookmarks = loadBookmarks()
        isBookmarked = bookmarks.contains { $0.pageNumber == currentPage && $0.granthTitle == title }
    }

    private func addBookmark(_ bookmark: Bookmark) {
        var bookmarks = loadBookmarks()
        bookmarks.removeAll { $0.pageNumber == bookmark.pageNumber && $0.granthTitle == bookmark.granthTitle }
        bookmarks.append(bookmark)
        saveBookmarks(bookmarks)
        checkBookmarkStatus()
    }

    private func removeBookmark(for pageNumber: Int) {
        var bookmarks = loadBookmarks()
        bookmarks.removeAll { $0.pageNumber == pageNumber && $0.granthTitle == title }
        saveBookmarks(bookmarks)
        checkBookmarkStatus()
    }

    private func loadBookmarks() -> [Bookmark] {
        if let data = UserDefaults.standard.data(forKey: "bookmarksWithTitles"),
           let bookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) {
            return bookmarks
        } else {
            let oldBookmarks = UserDefaults.standard.array(forKey: "bookmarkedPages") as? [Int] ?? []
            let newBookmarks = oldBookmarks.map { Bookmark(pageNumber: $0, granthTitle: title) }
            saveBookmarks(newBookmarks)
            return newBookmarks
        }
    }

    private func saveBookmarks(_ bookmarks: [Bookmark]) {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(encoded, forKey: "bookmarksWithTitles")
        }
        let pageNumbers = bookmarks.map { $0.pageNumber }
        UserDefaults.standard.set(pageNumbers, forKey: "bookmarkedPages")
    }
}

// MARK: - PDFKitView Wrapper

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    @Binding var currentPage: Int
    @Binding var pdfViewRef: PDFView?
    @Binding var totalPages: Int

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.backgroundColor = .white
        pdfView.documentView?.backgroundColor = .white
        pdfView.displaysPageBreaks = false
        pdfView.displayBox = .cropBox

        pdfView.delegate = context.coordinator

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(context.coordinator.pageDidChange(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        DispatchQueue.main.async {
            pdfViewRef = pdfView
            totalPages = document.pageCount
            if let page = pdfView.currentPage,
               let index = pdfView.document?.index(for: page) {
                context.coordinator.currentPage = index
            }
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let page = uiView.currentPage,
           let index = uiView.document?.index(for: page),
           index != currentPage {
            currentPage = index
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(currentPage: $currentPage)
    }

    class Coordinator: NSObject, PDFViewDelegate {
        @Binding var currentPage: Int

        init(currentPage: Binding<Int>) {
            _currentPage = currentPage
        }

        @objc func pageDidChange(_ notification: Notification) {
            if let pdfView = notification.object as? PDFView,
               let page = pdfView.currentPage,
               let index = pdfView.document?.index(for: page) {
                DispatchQueue.main.async {
                    self.currentPage = index
                }
            }
        }

        func pdfViewWillChangePage(_ pdfView: PDFView, to page: PDFPage) {
            if let index = pdfView.document?.index(for: page) {
                DispatchQueue.main.async {
                    self.currentPage = index
                }
            }
        }
    }

    static func dismantleUIView(_ uiView: PDFView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator, name: .PDFViewPageChanged, object: uiView)
    }
}

// MARK: - Preview

#Preview {
    let sampleURL = Bundle.main.url(forResource: "sarbloh_granth", withExtension: "pdf")
    return NavigationStack {
        PDFViewerView(pdfURL: sampleURL, title: "ਸਰਬਲੋਹ ਗ੍ਰੰਥ")
    }
}
