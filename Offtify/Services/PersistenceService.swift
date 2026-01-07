//
//  PersistenceService.swift
//  Offtify
//
//  Handles persistent storage for library and playlists
//

import Foundation

/// Service for persisting app data to disk
final class PersistenceService {
    
    // MARK: - Singleton
    
    static let shared = PersistenceService()
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    
    /// Base directory for app data
    private var appSupportDirectory: URL {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = urls[0].appendingPathComponent("Offtify", isDirectory: true)
        
        // Create directory if needed
        if !fileManager.fileExists(atPath: appSupport.path) {
            try? fileManager.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }
        
        return appSupport
    }
    
    /// Library data file
    private var libraryURL: URL {
        appSupportDirectory.appendingPathComponent("library.json")
    }
    
    /// Playlists data file
    private var playlistsURL: URL {
        appSupportDirectory.appendingPathComponent("playlists.json")
    }
    
    /// Artwork cache directory
    private var artworkCacheDirectory: URL {
        let dir = appSupportDirectory.appendingPathComponent("Artwork", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    // MARK: - Initialization
    
    private init() {
        setupDirectories()
    }
    
    private func setupDirectories() {
        // Ensure all directories exist
        _ = appSupportDirectory
        _ = artworkCacheDirectory
    }
    
    // MARK: - Library Persistence
    
    /// Save tracks to persistent storage
    func saveTracks(_ tracks: [Track]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(tracks)
        try data.write(to: libraryURL)
        
        // Cache artwork separately for large images
        for track in tracks {
            if let artworkData = track.artworkData {
                saveArtwork(artworkData, for: track.id)
            }
        }
    }
    
    /// Load tracks from persistent storage
    func loadTracks() throws -> [Track] {
        guard fileManager.fileExists(atPath: libraryURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: libraryURL)
        var tracks = try JSONDecoder().decode([Track].self, from: data)
        
        // Load cached artwork
        for i in tracks.indices {
            if let artworkData = loadArtwork(for: tracks[i].id) {
                tracks[i].artworkData = artworkData
            }
        }
        
        return tracks
    }
    
    /// Check if library exists
    func hasLibrary() -> Bool {
        fileManager.fileExists(atPath: libraryURL.path)
    }
    
    /// Clear library
    func clearLibrary() throws {
        if fileManager.fileExists(atPath: libraryURL.path) {
            try fileManager.removeItem(at: libraryURL)
        }
        // Clear artwork cache
        if fileManager.fileExists(atPath: artworkCacheDirectory.path) {
            try fileManager.removeItem(at: artworkCacheDirectory)
            try fileManager.createDirectory(at: artworkCacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Artwork Cache
    
    /// Save artwork to cache
    func saveArtwork(_ data: Data, for trackId: UUID) {
        let url = artworkCacheDirectory.appendingPathComponent("\(trackId.uuidString).jpg")
        try? data.write(to: url)
    }
    
    /// Load artwork from cache
    func loadArtwork(for trackId: UUID) -> Data? {
        let url = artworkCacheDirectory.appendingPathComponent("\(trackId.uuidString).jpg")
        return try? Data(contentsOf: url)
    }
    
    // MARK: - Playlist Persistence
    
    /// Save playlists to persistent storage
    func savePlaylists(_ playlists: [Playlist]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(playlists)
        try data.write(to: playlistsURL)
    }
    
    /// Load playlists from persistent storage
    func loadPlaylists() throws -> [Playlist] {
        guard fileManager.fileExists(atPath: playlistsURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: playlistsURL)
        return try JSONDecoder().decode([Playlist].self, from: data)
    }
    
    /// Add a new playlist
    func addPlaylist(_ playlist: Playlist) throws {
        var playlists = try loadPlaylists()
        playlists.append(playlist)
        try savePlaylists(playlists)
    }
    
    /// Update a playlist
    func updatePlaylist(_ playlist: Playlist) throws {
        var playlists = try loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index] = playlist
            try savePlaylists(playlists)
        }
    }
    
    /// Delete a playlist
    func deletePlaylist(_ playlistId: UUID) throws {
        var playlists = try loadPlaylists()
        playlists.removeAll { $0.id == playlistId }
        try savePlaylists(playlists)
    }
    
    // MARK: - Library Metadata
    
    /// Library info (source folder path)
    private var libraryInfoURL: URL {
        appSupportDirectory.appendingPathComponent("library_info.json")
    }
    
    struct LibraryInfo: Codable {
        var sourcePath: String
        var lastScanDate: Date
        var trackCount: Int
    }
    
    /// Save library info
    func saveLibraryInfo(sourcePath: String, trackCount: Int) throws {
        let info = LibraryInfo(sourcePath: sourcePath, lastScanDate: Date(), trackCount: trackCount)
        let data = try JSONEncoder().encode(info)
        try data.write(to: libraryInfoURL)
    }
    
    /// Load library info
    func loadLibraryInfo() throws -> LibraryInfo? {
        guard fileManager.fileExists(atPath: libraryInfoURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: libraryInfoURL)
        return try JSONDecoder().decode(LibraryInfo.self, from: data)
    }
}
