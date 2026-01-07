//
//  Playlist.swift
//  Offtify
//
//  Playlist model for managing collections of tracks
//

import Foundation
import AppKit

/// Represents a playlist with tracks
struct Playlist: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var description: String
    var trackIds: [UUID]
    var artworkData: Data?
    let createdAt: Date
    var updatedAt: Date
    
    /// Artwork image
    var artwork: NSImage? {
        guard let data = artworkData else { return nil }
        return NSImage(data: data)
    }
    
    /// Check if playlist is empty
    var isEmpty: Bool {
        trackIds.isEmpty
    }
    
    /// Number of tracks
    var trackCount: Int {
        trackIds.count
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        trackIds: [UUID] = [],
        artworkData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.trackIds = trackIds
        self.artworkData = artworkData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Mutating Methods
    
    mutating func addTrack(_ trackId: UUID) {
        if !trackIds.contains(trackId) {
            trackIds.append(trackId)
            updatedAt = Date()
        }
    }
    
    mutating func addTracks(_ ids: [UUID]) {
        for trackId in ids {
            if !trackIds.contains(trackId) {
                trackIds.append(trackId)
            }
        }
        updatedAt = Date()
    }
    
    mutating func removeTrack(_ trackId: UUID) {
        trackIds.removeAll { $0 == trackId }
        updatedAt = Date()
    }
    
    mutating func removeTrack(at index: Int) {
        guard trackIds.indices.contains(index) else { return }
        trackIds.remove(at: index)
        updatedAt = Date()
    }
    
    mutating func moveTrack(from source: IndexSet, to destination: Int) {
        trackIds.move(fromOffsets: source, toOffset: destination)
        updatedAt = Date()
    }
    
    mutating func rename(to newName: String) {
        name = newName
        updatedAt = Date()
    }
    
    mutating func updateDescription(_ newDescription: String) {
        description = newDescription
        updatedAt = Date()
    }
    
    mutating func setArtwork(_ data: Data?) {
        artworkData = data
        updatedAt = Date()
    }
}

// MARK: - Sample Playlists

extension Playlist {
    static let favorites = Playlist(
        name: "Favorites",
        description: "Your favorite tracks"
    )
    
    static func newPlaylist(name: String = "New Playlist") -> Playlist {
        Playlist(name: name)
    }
}
