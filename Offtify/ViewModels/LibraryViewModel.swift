//
//  LibraryViewModel.swift
//  Offtify
//
//  ViewModel for managing the music library
//

import Foundation
import Combine
import AppKit

/// Navigation destinations for the sidebar
enum NavigationDestination: String, CaseIterable, Identifiable {
    case home = "Home"
    case library = "Library"
    case albums = "Albums"
    case artists = "Artists"
    case playlists = "Playlists"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .library: return "music.note.list"
        case .albums: return "square.stack.fill"
        case .artists: return "person.2.fill"
        case .playlists: return "list.bullet"
        }
    }
}

/// View model for the music library
@MainActor
final class LibraryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var tracks: [Track] = []
    @Published var filteredTracks: [Track] = []
    @Published var searchQuery: String = ""
    @Published var selectedDestination: NavigationDestination = .library
    @Published var isLoading: Bool = false
    @Published var hasLoadedLibrary: Bool = false
    @Published var libraryPath: String = ""
    @Published var recentlyPlayed: [Track] = []
    @Published var lastScanDate: Date?
    
    // MARK: - Computed Properties
    
    var albums: [String: [Track]] {
        Dictionary(grouping: tracks) { $0.album }
    }
    
    var artists: [String: [Track]] {
        Dictionary(grouping: tracks) { $0.artist }
    }
    
    var uniqueAlbums: [String] {
        Array(Set(tracks.map { $0.album })).sorted()
    }
    
    var uniqueArtists: [String] {
        Array(Set(tracks.map { $0.artist })).sorted()
    }
    
    var trackCount: Int {
        tracks.count
    }
    
    // MARK: - Private Properties
    
    private let libraryService = MusicLibraryService.shared
    private let persistence = PersistenceService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        loadPersistedData()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Filter tracks based on search query
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.filterTracks(query: query)
            }
            .store(in: &cancellables)
        
        // Observe scan progress
        libraryService.$isScanning
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
    }
    
    /// Load data from persistent storage (primary) or cache (fallback)
    private func loadPersistedData() {
        isLoading = true
        
        // Try to load from persistent storage first
        do {
            let persistedTracks = try persistence.loadTracks()
            if !persistedTracks.isEmpty {
                tracks = persistedTracks
                filteredTracks = persistedTracks
                hasLoadedLibrary = true
                
                // Load library info
                if let info = try? persistence.loadLibraryInfo() {
                    libraryPath = info.sourcePath
                    lastScanDate = info.lastScanDate
                }
            } else {
                // Fallback to cache (legacy)
                loadCachedData()
            }
        } catch {
            print("Failed to load persisted tracks: \(error)")
            loadCachedData()
        }
        
        // Load recently played
        loadRecentlyPlayed()
        
        isLoading = false
    }
    
    /// Legacy cache loading
    private func loadCachedData() {
        if let cachedTracks = libraryService.loadCachedTracks() {
            tracks = cachedTracks
            filteredTracks = cachedTracks
            hasLoadedLibrary = true
            
            // Migrate to persistent storage
            Task {
                await saveToPeristentStorage()
            }
        }
        
        if let savedPath = libraryService.getSavedFolderPath() {
            libraryPath = savedPath.path
        }
    }
    
    // MARK: - Public Methods
    
    /// Select and scan a music folder
    func selectMusicFolder() {
        guard let folderURL = libraryService.selectMusicFolder() else {
            return
        }
        
        libraryPath = folderURL.path
        scanLibrary(at: folderURL)
    }
    
    /// Rescan the current library
    func rescanLibrary() {
        guard let folderURL = libraryService.getSavedFolderPath() ?? libraryService.resolveBookmarkedURL() else {
            selectMusicFolder()
            return
        }
        
        scanLibrary(at: folderURL)
    }
    
    /// Import music from file picker
    func importMusic() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.audio]
        
        panel.begin { [weak self] response in
            guard let self = self, response == .OK else { return }
            
            for url in panel.urls {
                if url.hasDirectoryPath {
                    self.scanLibrary(at: url)
                } else {
                    // It's a file, handle single file import
                    Task {
                        if let track = await self.libraryService.loadMetadata(for: url) {
                            await MainActor.run {
                                if !self.tracks.contains(where: { $0.id == track.id }) {
                                    self.tracks.append(track)
                                    self.filterTracks(query: self.searchQuery)
                                    self.hasLoadedLibrary = true
                                }
                            }
                            await self.saveToPeristentStorage()
                        }
                    }
                }
            }
        }
    }
    
    /// Clear all music from the library
    func clearAllMusic() {
        // Clear in-memory
        tracks.removeAll()
        filteredTracks.removeAll()
        hasLoadedLibrary = false
        
        // Clear persistence
        Task {
            await saveToPeristentStorage()
        }
        
        // Clear service cache
        libraryService.clearCache()
    }
    
    /// Scan a specific folder
    private func scanLibrary(at folderURL: URL) {
        Task {
            isLoading = true
            let loadedTracks = await libraryService.scanAndLoadTracks(from: folderURL)
            
            await MainActor.run {
                // Merge with existing tracks avoiding duplicates
                let existingIds = Set(self.tracks.map { $0.id })
                let newTracks = loadedTracks.filter { !existingIds.contains($0.id) }
                
                self.tracks.append(contentsOf: newTracks)
                self.filterTracks(query: self.searchQuery) // Re-apply filter after adding new tracks
                self.hasLoadedLibrary = true
                self.lastScanDate = Date()
                self.isLoading = false
            }
            
            // Save to persistent storage
            await saveToPeristentStorage()
        }
    }
    
    /// Save tracks to persistent storage
    private func saveToPeristentStorage() async {
        do {
            try persistence.saveTracks(tracks)
            try persistence.saveLibraryInfo(sourcePath: libraryPath, trackCount: tracks.count)
            print("Library saved to persistent storage: \(tracks.count) tracks")
        } catch {
            print("Failed to save to persistent storage: \(error)")
        }
    }
    
    /// Filter tracks based on search query
    private func filterTracks(query: String) {
        if query.isEmpty {
            filteredTracks = tracks
        } else {
            let lowercasedQuery = query.lowercased()
            filteredTracks = tracks.filter { track in
                track.title.lowercased().contains(lowercasedQuery) ||
                track.artist.lowercased().contains(lowercasedQuery) ||
                track.album.lowercased().contains(lowercasedQuery)
            }
        }
    }
    
    /// Get tracks for a specific album
    func tracks(forAlbum album: String) -> [Track] {
        tracks.filter { $0.album == album }
    }
    
    /// Get tracks for a specific artist
    func tracks(forArtist artist: String) -> [Track] {
        tracks.filter { $0.artist == artist }
    }
    
    /// Get track by ID
    func track(byId id: UUID) -> Track? {
        tracks.first { $0.id == id }
    }
    
    /// Get tracks by IDs
    func tracks(byIds ids: [UUID]) -> [Track] {
        ids.compactMap { id in tracks.first { $0.id == id } }
    }
    
    /// Add track to recently played
    func addToRecentlyPlayed(_ track: Track) {
        // Remove if already exists
        recentlyPlayed.removeAll { $0.id == track.id }
        
        // Add to beginning
        recentlyPlayed.insert(track, at: 0)
        
        // Keep only last 20
        if recentlyPlayed.count > 20 {
            recentlyPlayed = Array(recentlyPlayed.prefix(20))
        }
        
        saveRecentlyPlayed()
    }
    
    /// Clear the library
    func clearLibrary() {
        libraryService.clearCache()
        try? persistence.clearLibrary()
        tracks = []
        filteredTracks = []
        hasLoadedLibrary = false
        libraryPath = ""
        lastScanDate = nil
    }
    
    // MARK: - Persistence
    
    private func saveRecentlyPlayed() {
        do {
            let data = try JSONEncoder().encode(recentlyPlayed)
            UserDefaults.standard.set(data, forKey: "offtify_recently_played")
        } catch {
            print("Failed to save recently played: \(error)")
        }
    }
    
    private func loadRecentlyPlayed() {
        guard let data = UserDefaults.standard.data(forKey: "offtify_recently_played") else {
            return
        }
        
        do {
            recentlyPlayed = try JSONDecoder().decode([Track].self, from: data)
        } catch {
            print("Failed to load recently played: \(error)")
        }
    }
}
