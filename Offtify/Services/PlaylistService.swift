//
//  PlaylistService.swift
//  Offtify
//
//  Service for managing playlists
//

import Foundation
import Combine

/// Service for playlist CRUD operations
final class PlaylistService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = PlaylistService()
    
    // MARK: - Published Properties
    
    @Published private(set) var playlists: [Playlist] = []
    @Published private(set) var isLoading: Bool = false
    
    // MARK: - Properties
    
    private let persistence = PersistenceService.shared
    
    // MARK: - Initialization
    
    private init() {
        loadPlaylists()
    }
    
    // MARK: - CRUD Operations
    
    /// Load all playlists from storage
    func loadPlaylists() {
        isLoading = true
        
        do {
            playlists = try persistence.loadPlaylists()
        } catch {
            print("Failed to load playlists: \(error)")
            playlists = []
        }
        
        isLoading = false
    }
    
    /// Create a new playlist
    @discardableResult
    func createPlaylist(name: String, description: String = "") -> Playlist {
        let playlist = Playlist(name: name, description: description)
        playlists.append(playlist)
        save()
        return playlist
    }
    
    /// Get a playlist by ID
    func getPlaylist(by id: UUID) -> Playlist? {
        playlists.first { $0.id == id }
    }
    
    /// Update a playlist
    func updatePlaylist(_ playlist: Playlist) {
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index] = playlist
            save()
        }
    }
    
    /// Rename a playlist
    func renamePlaylist(_ id: UUID, to newName: String) {
        if let index = playlists.firstIndex(where: { $0.id == id }) {
            playlists[index].rename(to: newName)
            save()
        }
    }
    
    /// Delete a playlist
    func deletePlaylist(_ id: UUID) {
        playlists.removeAll { $0.id == id }
        save()
    }
    
    /// Delete playlists at offsets
    func deletePlaylists(at offsets: IndexSet) {
        playlists.remove(atOffsets: offsets)
        save()
    }
    
    // MARK: - Track Operations
    
    /// Add a track to a playlist
    func addTrack(_ trackId: UUID, to playlistId: UUID) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[index].addTrack(trackId)
            save()
        }
    }
    
    /// Add multiple tracks to a playlist
    func addTracks(_ trackIds: [UUID], to playlistId: UUID) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[index].addTracks(trackIds)
            save()
        }
    }
    
    /// Remove a track from a playlist
    func removeTrack(_ trackId: UUID, from playlistId: UUID) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[index].removeTrack(trackId)
            save()
        }
    }
    
    /// Remove track at index from a playlist
    func removeTrack(at index: Int, from playlistId: UUID) {
        if let playlistIndex = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[playlistIndex].removeTrack(at: index)
            save()
        }
    }
    
    /// Move track within a playlist
    func moveTrack(from source: IndexSet, to destination: Int, in playlistId: UUID) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[index].moveTrack(from: source, to: destination)
            save()
        }
    }
    
    /// Check if a track is in a playlist
    func isTrack(_ trackId: UUID, inPlaylist playlistId: UUID) -> Bool {
        guard let playlist = getPlaylist(by: playlistId) else { return false }
        return playlist.trackIds.contains(trackId)
    }
    
    /// Get playlists containing a track
    func getPlaylists(containingTrack trackId: UUID) -> [Playlist] {
        playlists.filter { $0.trackIds.contains(trackId) }
    }
    
    // MARK: - Artwork
    
    /// Set artwork for a playlist
    func setArtwork(_ data: Data?, for playlistId: UUID) {
        if let index = playlists.firstIndex(where: { $0.id == playlistId }) {
            playlists[index].setArtwork(data)
            save()
        }
    }
    
    // MARK: - Private
    
    private func save() {
        do {
            try persistence.savePlaylists(playlists)
        } catch {
            print("Failed to save playlists: \(error)")
        }
    }
}
