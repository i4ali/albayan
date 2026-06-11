//
//  BookmarksView.swift
//  AlBayan
//
//  Modern bookmarks management with glassmorphism design
//

import SwiftUI

enum SwipeDirection {
    case up, down
}

struct BookmarksView: View {
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedBookmark: Bookmark?
    @State private var showingBookmarkDetail = false
    @State private var searchText = ""
    @State private var selectedSortOrder: BookmarkSortOrder = .dateDescending
    @State private var focusedBookmarkIndex: Int = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            themeManager.primaryBackground
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ModernBookmarksHeader(
                    bookmarkCount: filteredBookmarks.count,
                    onSortChange: { selectedSortOrder = $0 }
                )
                
                // Content
                if bookmarkManager.isLoading {
                    BookmarksLoadingView()
                } else if filteredBookmarks.isEmpty {
                    EmptyBookmarksView()
                } else {
                    BookmarksListView(
                        bookmarks: filteredBookmarks,
                        dataManager: dataManager,
                        focusedIndex: $focusedBookmarkIndex,
                        onSwipeNavigation: handleSwipeNavigation
                    )
                }
                
            }
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if themeManager.isSapphire {
                ToolbarItem(placement: .principal) {
                    Text("Bookmarks")
                        .font(SapphireFont.screenTitle)
                        .foregroundColor(themeManager.primaryText)
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .searchable(text: $searchText, prompt: "Search bookmarks...")
        .sheet(isPresented: $showingBookmarkDetail) {
            if let bookmark = selectedBookmark {
                BookmarkDetailView(bookmark: bookmark)
            }
        }
    }
    
    private func handleSwipeNavigation(fromIndex: Int, direction: SwipeDirection) {
        let bookmarks = filteredBookmarks
        guard !bookmarks.isEmpty && fromIndex >= 0 && fromIndex < bookmarks.count else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            // Simply set focus to the bookmark that was swiped on
            focusedBookmarkIndex = fromIndex
        }
    }
    
    private var filteredBookmarks: [Bookmark] {
        let sorted = bookmarkManager.getSortedBookmarks()
        
        if searchText.isEmpty {
            return sorted
        }
        
        return sorted.filter { bookmark in
            bookmark.surahName.localizedCaseInsensitiveContains(searchText) ||
            bookmark.verseTranslation.localizedCaseInsensitiveContains(searchText) ||
            bookmark.notes?.localizedCaseInsensitiveContains(searchText) == true ||
            bookmark.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct ModernBookmarksHeader: View {
    let bookmarkCount: Int
    let onSortChange: (BookmarkSortOrder) -> Void
    @State private var showingSortOptions = false
    @State private var showingClearAllConfirmation = false
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var bookmarkManager = BookmarkManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and sort button
            HStack {
                VStack(spacing: 4) {
                    if bookmarkCount > 0 {
                        Text("\(bookmarkCount) saved")
                            .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                            .tracking(themeManager.isSapphire ? 2 : 0)
                            .textCase(themeManager.isSapphire ? .uppercase : .none)
                    }
                }
                
                Spacer()
                
                Button(action: { showingSortOptions = true }) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeManager.primaryText)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(themeManager.glassEffect)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(themeManager.strokeColor, lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .confirmationDialog("Bookmark Options", isPresented: $showingSortOptions) {
            Section("Sort Options") {
                ForEach(BookmarkSortOrder.allCases, id: \.self) { sortOrder in
                    Button(sortOrder.title) {
                        onSortChange(sortOrder)
                    }
                }
            }
            
            if bookmarkCount > 0 {
                Section {
                    Button("Clear All Bookmarks", role: .destructive) {
                        showingClearAllConfirmation = true
                    }
                }
            }
        }
        .alert("Clear All Bookmarks?", isPresented: $showingClearAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                bookmarkManager.bookmarks.forEach { bookmark in
                    bookmarkManager.removeBookmark(id: bookmark.id)
                }
            }
        } message: {
            Text("This will permanently delete all \(bookmarkCount) bookmarks. This action cannot be undone.")
        }
    }
}

struct BookmarksListView: View {
    let bookmarks: [Bookmark]
    let dataManager: DataManager
    @Binding var focusedIndex: Int
    let onSwipeNavigation: (Int, SwipeDirection) -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @State private var bookmarkToDelete: Bookmark?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(bookmarks.enumerated()), id: \.element.id) { index, bookmark in
                        if let surahWithTafsir = createSurahWithTafsir(for: bookmark) {
                            NavigationLink(destination: SurahDetailView(surahWithTafsir: surahWithTafsir, targetVerse: bookmark.verseNumber)) {
                                BookmarkCardContent(
                                    bookmark: bookmark,
                                    index: index,
                                    isFocused: index == focusedIndex,
                                    onSwipe: onSwipeNavigation,
                                    onDelete: { 
                                        bookmarkToDelete = bookmark
                                        showingDeleteConfirmation = true
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(bookmark.id)
                        } else {
                            BookmarkCard(
                                bookmark: bookmark,
                                index: index,
                                isFocused: index == focusedIndex,
                                onSwipe: onSwipeNavigation,
                                onDelete: { 
                                    bookmarkToDelete = bookmark
                                    showingDeleteConfirmation = true
                                }
                            )
                            .id(bookmark.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .onChange(of: focusedIndex) { _, newIndex in
                if newIndex >= 0 && newIndex < bookmarks.count {
                    let targetId = bookmarks[newIndex].id
                    withAnimation(.easeInOut(duration: 0.6)) {
                        proxy.scrollTo(targetId, anchor: .center)
                    }
                }
            }
        }
        .alert("Delete Bookmark?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let bookmark = bookmarkToDelete {
                    bookmarkManager.removeBookmark(id: bookmark.id)
                    bookmarkToDelete = nil
                }
            }
        } message: {
            if let bookmark = bookmarkToDelete {
                Text("Are you sure you want to delete the bookmark for \(bookmark.surahName) verse \(bookmark.verseNumber)?")
            }
        }
    }
    
    private func createSurahWithTafsir(for bookmark: Bookmark) -> SurahWithTafsir? {
        // First try to find in available surahs (with tafsir)
        if let surahWithTafsir = dataManager.availableSurahs.first(where: { $0.surah.number == bookmark.surahNumber }) {
            return surahWithTafsir
        }
        
        // Fallback to create from quran data (without tafsir)
        guard let quranData = dataManager.quranData,
              let surah = quranData.surahs.first(where: { $0.number == bookmark.surahNumber }),
              let surahVerses = quranData.verses[String(bookmark.surahNumber)] else {
            return nil
        }
        
        var verses: [VerseWithTafsir] = []
        for i in 1...surah.versesCount {
            let verseKey = String(i)
            if let verse = surahVerses[verseKey] {
                let verseWithTafsir = VerseWithTafsir(
                    number: i,
                    verse: verse,
                    tafsir: nil
                )
                verses.append(verseWithTafsir)
            }
        }
        
        return SurahWithTafsir(surah: surah, verses: verses)
    }
}

struct BookmarkCardContent: View {
    let bookmark: Bookmark
    let index: Int
    let isFocused: Bool
    let onSwipe: (Int, SwipeDirection) -> Void
    let onDelete: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @State private var isPressed = false
    @State private var showingDeleteButton = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with surah info and delete button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.surahName)
                        .font(themeManager.isSapphire ? SapphireFont.serif(19) : .system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.primaryText)

                    Text("Verse \(bookmark.verseNumber)")
                        .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                        .tracking(themeManager.isSapphire ? 2 : 0)
                        .textCase(themeManager.isSapphire ? .uppercase : .none)
                }

                Spacer()

                HStack(spacing: 8) {
                    if showingDeleteButton {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.1))
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    Button(action: onDelete) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.pink)
                    }
                }
            }

            // Verse translation preview
            Text(bookmark.verseTranslation)
                .font(themeManager.isSapphire ? SapphireFont.serif(15, semibold: false) : .system(size: 14, weight: .medium))
                .foregroundColor(themeManager.secondaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Tags if any
            if !bookmark.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(bookmark.tags, id: \.self) { tag in
                            Text(tag)
                                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 10, weight: .medium))
                                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.primaryText)
                                .tracking(themeManager.isSapphire ? 2 : 0)
                                .textCase(themeManager.isSapphire ? .uppercase : .none)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.isSapphire ? AnyShapeStyle(themeManager.goldChipFill) : AnyShapeStyle(themeManager.accentGradient))
                                        .overlay(
                                            themeManager.isSapphire ?
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(themeManager.strokeColor, lineWidth: 1)
                                            : nil
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }

            // Date
            HStack {
                Spacer()
                Text(bookmark.createdAt, style: .date)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(themeManager.tertiaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.glassEffect)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isFocused
                                ? (themeManager.isSapphire ? themeManager.accentColor : Color.blue.opacity(0.6))
                                : themeManager.strokeColor,
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .overlay(
                    // Focus indicator
                    isFocused ? RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.isSapphire ? themeManager.accentColor.opacity(0.08) : Color.blue.opacity(0.1))
                        .animation(.easeInOut(duration: 0.3), value: isFocused)
                    : nil
                )
        )
        .scaleEffect(isPressed ? 0.98 : (isFocused ? 1.02 : 1.0))
        .offset(dragOffset)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: isFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingDeleteButton)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
        .onLongPressGesture(minimumDuration: 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingDeleteButton.toggle()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    isPressed = true
                    let translation = value.translation
                    dragOffset = CGSize(width: 0, height: translation.height * 0.3)
                }
                .onEnded { value in
                    isPressed = false

                    // Determine swipe direction based on vertical movement
                    let translation = value.translation
                    let swipeThreshold: CGFloat = 50
                    if abs(translation.height) > swipeThreshold {
                        if translation.height < 0 {
                            // Swiped up - show next bookmark (scroll screen down)
                            onSwipe(index, .up)
                        } else {
                            // Swiped down - show previous bookmark (scroll screen up)
                            onSwipe(index, .down)
                        }
                    }

                    // Reset drag offset
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
        )
    }
}

struct BookmarkCard: View {
    let bookmark: Bookmark
    let index: Int
    let isFocused: Bool
    let onSwipe: (Int, SwipeDirection) -> Void
    let onDelete: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var bookmarkManager = BookmarkManager.shared
    @State private var isPressed = false
    @State private var showingDeleteButton = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with surah info and delete button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bookmark.surahName)
                        .font(themeManager.isSapphire ? SapphireFont.serif(19) : .system(size: 16, weight: .semibold))
                        .foregroundColor(themeManager.primaryText)

                    Text("Verse \(bookmark.verseNumber)")
                        .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 12, weight: .medium))
                        .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                        .tracking(themeManager.isSapphire ? 2 : 0)
                        .textCase(themeManager.isSapphire ? .uppercase : .none)
                }

                Spacer()

                HStack(spacing: 8) {
                    if showingDeleteButton {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.1))
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    Button(action: onDelete) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.pink)
                    }
                }
            }

            // Verse translation preview
            Text(bookmark.verseTranslation)
                .font(themeManager.isSapphire ? SapphireFont.serif(15, semibold: false) : .system(size: 14, weight: .medium))
                .foregroundColor(themeManager.secondaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Tags if any
            if !bookmark.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(bookmark.tags, id: \.self) { tag in
                            Text(tag)
                                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 10, weight: .medium))
                                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.primaryText)
                                .tracking(themeManager.isSapphire ? 2 : 0)
                                .textCase(themeManager.isSapphire ? .uppercase : .none)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.isSapphire ? AnyShapeStyle(themeManager.goldChipFill) : AnyShapeStyle(themeManager.accentGradient))
                                        .overlay(
                                            themeManager.isSapphire ?
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(themeManager.strokeColor, lineWidth: 1)
                                            : nil
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }

            // Date
            HStack {
                Spacer()
                Text(bookmark.createdAt, style: .date)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(themeManager.tertiaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.glassEffect)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isFocused
                                ? (themeManager.isSapphire ? themeManager.accentColor : Color.blue.opacity(0.6))
                                : themeManager.strokeColor,
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .overlay(
                    // Focus indicator
                    isFocused ? RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.isSapphire ? themeManager.accentColor.opacity(0.08) : Color.blue.opacity(0.1))
                        .animation(.easeInOut(duration: 0.3), value: isFocused)
                    : nil
                )
        )
        .scaleEffect(isPressed ? 0.98 : (isFocused ? 1.02 : 1.0))
        .offset(dragOffset)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: isFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingDeleteButton)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: dragOffset)
        .onLongPressGesture(minimumDuration: 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingDeleteButton.toggle()
            }
        }
        .onTapGesture {
            if showingDeleteButton {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingDeleteButton = false
                }
            }
            // This is the fallback case - no navigation here
        }
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    isPressed = true
                    let translation = value.translation
                    dragOffset = CGSize(width: 0, height: translation.height * 0.3)
                }
                .onEnded { value in
                    isPressed = false

                    // Determine swipe direction based on vertical movement
                    let translation = value.translation
                    let swipeThreshold: CGFloat = 50
                    if abs(translation.height) > swipeThreshold {
                        if translation.height < 0 {
                            // Swiped up - show next bookmark (scroll screen down)
                            onSwipe(index, .up)
                        } else {
                            // Swiped down - show previous bookmark (scroll screen up)
                            onSwipe(index, .down)
                        }
                    }

                    // Reset drag offset
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                }
        )
    }
}

struct EmptyBookmarksView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "heart")
                .font(.system(size: 60, weight: .thin))
                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)

            VStack(spacing: 8) {
                Text("No Bookmarks Yet")
                    .font(themeManager.isSapphire ? SapphireFont.headline(22) : .system(size: 20, weight: .semibold))
                    .foregroundColor(themeManager.primaryText)

                Text("Tap the heart icon on any verse to save it for later reading")
                    .font(themeManager.isSapphire ? SapphireFont.serif(15, semibold: false) : .system(size: 14))
                    .foregroundColor(themeManager.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}


struct BookmarksLoadingView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.primaryText))
                .scaleEffect(1.2)
            
            Text("Loading bookmarks...")
                .font(.system(size: 14))
                .foregroundColor(themeManager.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BookmarkDetailView: View {
    let bookmark: Bookmark
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                themeManager.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Surah and verse info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(bookmark.surahName)
                                .font(themeManager.isSapphire ? SapphireFont.headline(24) : .system(size: 24, weight: .bold))
                                .foregroundColor(themeManager.primaryText)

                            Text("Verse \(bookmark.verseNumber)")
                                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                                .tracking(themeManager.isSapphire ? 2 : 0)
                                .textCase(themeManager.isSapphire ? .uppercase : .none)
                        }

                        // Arabic text
                        Text(bookmark.verseText)
                            .font(themeManager.isSapphire ? SapphireFont.arabic(24) : .system(size: 22, weight: .medium))
                            .foregroundColor(themeManager.primaryText)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .lineSpacing(themeManager.isSapphire ? 14 : 6)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(themeManager.glassEffect)
                            )

                        // Translation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Translation")
                                .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .semibold))
                                .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                                .tracking(themeManager.isSapphire ? 2 : 0)
                                .textCase(themeManager.isSapphire ? .uppercase : .none)

                            Text(bookmark.verseTranslation)
                                .font(themeManager.isSapphire ? SapphireFont.serif(16, semibold: false) : .system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.primaryText)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(themeManager.glassEffect)
                        )

                        // Notes if any
                        if let notes = bookmark.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .semibold))
                                    .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                                    .tracking(themeManager.isSapphire ? 2 : 0)
                                    .textCase(themeManager.isSapphire ? .uppercase : .none)

                                Text(notes)
                                    .font(themeManager.isSapphire ? SapphireFont.serif(16, semibold: false) : .system(size: 16))
                                    .foregroundColor(themeManager.primaryText)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(themeManager.glassEffect)
                            )
                        }

                        // Tags if any
                        if !bookmark.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tags")
                                    .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 14, weight: .semibold))
                                    .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.secondaryText)
                                    .tracking(themeManager.isSapphire ? 2 : 0)
                                    .textCase(themeManager.isSapphire ? .uppercase : .none)

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                    ForEach(bookmark.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(themeManager.isSapphire ? SapphireFont.eyebrow : .system(size: 12, weight: .medium))
                                            .foregroundColor(themeManager.isSapphire ? themeManager.accentColor : themeManager.primaryText)
                                            .tracking(themeManager.isSapphire ? 2 : 0)
                                            .textCase(themeManager.isSapphire ? .uppercase : .none)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(themeManager.isSapphire ? AnyShapeStyle(themeManager.goldChipFill) : AnyShapeStyle(themeManager.accentGradient))
                                                    .overlay(
                                                        themeManager.isSapphire ?
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(themeManager.strokeColor, lineWidth: 1)
                                                        : nil
                                                    )
                                            )
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
            .toolbarBackground(themeManager.primaryBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(themeManager.isSapphire ? SapphireFont.serif(16) : .body)
                    .foregroundColor(themeManager.isSapphire ? themeManager.onAccentText : themeManager.primaryText)
                    .padding(themeManager.isSapphire ? .horizontal : [])
                    .padding(themeManager.isSapphire ? .vertical : [], themeManager.isSapphire ? 6 : 0)
                    .background {
                        if themeManager.isSapphire {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AnyShapeStyle(themeManager.goldGradient))
                        }
                    }
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
}

#Preview {
    BookmarksView()
}