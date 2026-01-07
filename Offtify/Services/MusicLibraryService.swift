//
//  MusicLibraryService.swift
//  Offtify
//
//  Scans and manages local music library
//

import Foundation
import AppKit

/// Service for scanning and managing the local music library
final class MusicLibraryService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = MusicLibraryService()
    
    // MARK: - Published Properties
    
    @Published private(set) var isScanning = false
    @Published private(set) var scanProgress: Double = 0
    @Published private(set) var currentScanFile: String = ""
    
    // MARK: - Properties
    
    /// Supported audio file extensions
    private let supportedExtensions: Set<String> = ["mp3", "flac", "wav", "m4a", "aac", "aiff", "alac"]
    
    /// Cache key for storing library path
    private let libraryPathKey = "offtify_library_path"
    
    /// Cache key for storing track data
    private let trackCacheKey = "offtify_tracks_cache"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Open folder picker and return selected URL
    /// - Returns: The selected folder URL, or nil if cancelled
    @MainActor
    func selectMusicFolder() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Music Folder"
        openPanel.message = "Choose a folder containing your music files"
        openPanel.prompt = "Select"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = false
        
        let response = openPanel.runModal()
        
        guard response == .OK, let url = openPanel.url else {
            return nil
        }
        
        // Save the selected path
        saveFolderPath(url)
        
        return url
    }
    
    /// Scan a folder for audio files
    /// - Parameter folderURL: The folder to scan
    /// - Returns: Array of audio file URLs
    func scanFolder(_ folderURL: URL) async -> [URL] {
        await MainActor.run {
            isScanning = true
            scanProgress = 0
            currentScanFile = ""
        }
        
        var audioFiles: [URL] = []
        
        let fileManager = FileManager.default
        
        // Start accessing security-scoped resource
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()
        
        defer {
            if didStartAccessing {
                folderURL.stopAccessingSecurityScopedResource()
            }
            Task { @MainActor in
                isScanning = false
                scanProgress = 1.0
                currentScanFile = ""
            }
        }
        
        // Create directory enumerator
        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey, .contentTypeKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }
        
        // First pass: count total files for progress
        var allURLs: [URL] = []
        
        while let url = enumerator.nextObject() as? URL {
            let pathExtension = url.pathExtension.lowercased()
            if supportedExtensions.contains(pathExtension) {
                allURLs.append(url)
            }
        }
        
        let totalFiles = allURLs.count
        
        // Process files with progress
        for (index, url) in allURLs.enumerated() {
            audioFiles.append(url)
            
            await MainActor.run {
                scanProgress = Double(index + 1) / Double(max(totalFiles, 1))
                currentScanFile = url.lastPathComponent
            }
            
            // Small delay to prevent UI blocking
            if index % 10 == 0 {
                try? await Task.sleep(nanoseconds: 1_000_000)
            }
        }
        
        return audioFiles
    }
    
    /// Scan folder and extract metadata for all tracks
    /// - Parameter folderURL: The folder to scan
    /// - Returns: Array of Track objects
    func scanAndLoadTracks(from folderURL: URL) async -> [Track] {
        let audioURLs = await scanFolder(folderURL)
        
        await MainActor.run {
            currentScanFile = "Extracting metadata..."
        }
        
        let tracks = await MetadataService.shared.extractMetadata(from: audioURLs)
        
        // Cache the tracks
        cacheTracks(tracks)
        
        return tracks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
    
    /// Extract metadata for a single file
    /// - Parameter url: The file URL
    /// - Returns: Track object or nil
    func loadMetadata(for url: URL) async -> Track? {
        return await MetadataService.shared.extractMetadata(from: url)
    }
    
    /// Get the last used library folder path
    /// - Returns: The saved library URL, or nil if not set
    func getSavedFolderPath() -> URL? {
        guard let path = UserDefaults.standard.string(forKey: libraryPathKey) else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }
    
    /// Load cached tracks if available
    /// - Returns: Array of cached Track objects
    func loadCachedTracks() -> [Track]? {
        guard let data = UserDefaults.standard.data(forKey: trackCacheKey) else {
            return nil
        }
        
        do {
            let tracks = try JSONDecoder().decode([Track].self, from: data)
            return tracks
        } catch {
            print("Failed to decode cached tracks: \(error)")
            return nil
        }
    }
    
    /// Clear the track cache
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: trackCacheKey)
        UserDefaults.standard.removeObject(forKey: libraryPathKey)
    }
    
    // MARK: - Private Methods
    
    private func saveFolderPath(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: libraryPathKey)
        
        // Save security-scoped bookmark for persistent access
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: "\(libraryPathKey)_bookmark")
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }
    
    private func cacheTracks(_ tracks: [Track]) {
        do {
            let data = try JSONEncoder().encode(tracks)
            UserDefaults.standard.set(data, forKey: trackCacheKey)
        } catch {
            print("Failed to cache tracks: \(error)")
        }
    }
    
    /// Resolve a bookmarked URL
    func resolveBookmarkedURL() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: "\(libraryPathKey)_bookmark") else {
            return nil
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                // Re-save the bookmark
                saveFolderPath(url)
            }
            
            return url
        } catch {
            print("Failed to resolve bookmark: \(error)")
            return nil
        }
    }
}
