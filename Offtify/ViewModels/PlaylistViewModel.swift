//
//  PlaylistViewModel.swift
//  Offtify
//
//  ViewModel for managing playlists
//

import Foundation
import Combine

/// View model for playlist management
@MainActor
final class PlaylistViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var playlists: [Playlist] = []
    @Published var selectedPlaylist: Playlist?
    @Published var isCreatingPlaylist: Bool = false
    @Published var isEditingPlaylist: Bool = false
    @Published var newPlaylistName: String = ""
    @Published var editPlaylistName: String = ""
    
    // MARK: - Services
    
    private let playlistService = PlaylistService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var hasPlaylists: Bool {
        !playlists.isEmpty
    }
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        playlistService.$playlists
            .receive(on: DispatchQueue.main)
            .assign(to: &$playlists)
    }
    
    // MARK: - CRUD Operations
    
    /// Create a new playlist
    func createPlaylist() {
        let name = newPlaylistName.isEmpty ? "New Playlist" : newPlaylistName
        let playlist = playlistService.createPlaylist(name: name)
        selectedPlaylist = playlist
        newPlaylistName = ""
        isCreatingPlaylist = false
    }
    
    /// Create a playlist with a specific name
    func createPlaylist(name: String) -> Playlist {
        playlistService.createPlaylist(name: name)
    }
    
    /// Delete a playlist
    func deletePlaylist(_ playlist: Playlist) {
        playlistService.deletePlaylist(playlist.id)
        if selectedPlaylist?.id == playlist.id {
            selectedPlaylist = nil
        }
    }
    
    /// Delete playlists at offsets
    func deletePlaylists(at offsets: IndexSet) {
        playlistService.deletePlaylists(at: offsets)
    }
    
    /// Rename a playlist
    func renamePlaylist(_ playlist: Playlist, to newName: String) {
        playlistService.renamePlaylist(playlist.id, to: newName)
        isEditingPlaylist = false
        editPlaylistName = ""
    }
    
    /// Select a playlist
    func selectPlaylist(_ playlist: Playlist) {
        selectedPlaylist = playlist
    }
    
    /// Start editing a playlist
    func startEditing(_ playlist: Playlist) {
        selectedPlaylist = playlist
        editPlaylistName = playlist.name
        isEditingPlaylist = true
    }
    
    /// Cancel editing
    func cancelEditing() {
        isEditingPlaylist = false
        editPlaylistName = ""
    }
    
    /// Show create playlist dialog
    func showCreatePlaylist() {
        isCreatingPlaylist = true
        newPlaylistName = ""
    }
    
    /// Cancel create playlist
    func cancelCreatePlaylist() {
        isCreatingPlaylist = false
        newPlaylistName = ""
    }
    
    // MARK: - Track Operations
    
    /// Add a track to a playlist
    func addTrack(_ track: Track, to playlist: Playlist) {
        playlistService.addTrack(track.id, to: playlist.id)
    }
    
    /// Add tracks to a playlist
    func addTracks(_ tracks: [Track], to playlist: Playlist) {
        playlistService.addTracks(tracks.map { $0.id }, to: playlist.id)
    }
    
    /// Remove a track from a playlist
    func removeTrack(_ track: Track, from playlist: Playlist) {
        playlistService.removeTrack(track.id, from: playlist.id)
    }
    
    /// Remove track at index from a playlist
    func removeTrack(at index: Int, from playlist: Playlist) {
        playlistService.removeTrack(at: index, from: playlist.id)
    }
    
    /// Move track within a playlist
    func moveTrack(from source: IndexSet, to destination: Int, in playlist: Playlist) {
        playlistService.moveTrack(from: source, to: destination, in: playlist.id)
    }
    
    /// Check if a track is in a playlist
    func isTrack(_ track: Track, inPlaylist playlist: Playlist) -> Bool {
        playlistService.isTrack(track.id, inPlaylist: playlist.id)
    }
    
    /// Get tracks for a playlist
    func getTracks(for playlist: Playlist, from allTracks: [Track]) -> [Track] {
        playlist.trackIds.compactMap { trackId in
            allTracks.first { $0.id == trackId }
        }
    }
    
    /// Get playlists containing a track
    func getPlaylists(containingTrack track: Track) -> [Playlist] {
        playlistService.getPlaylists(containingTrack: track.id)
    }
}
