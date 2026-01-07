//
//  Track.swift
//  Offtify
//
//  A native macOS music player
//

import Foundation
import AppKit

/// Represents a music track with metadata
struct Track: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let fileURL: URL
    
    // Artwork is stored separately and not encoded
    var artworkData: Data?
    
    var artwork: NSImage? {
        guard let data = artworkData else { return nil }
        return NSImage(data: data)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String,
        duration: TimeInterval,
        fileURL: URL,
        artworkData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.fileURL = fileURL
        self.artworkData = artworkData
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, title, artist, album, duration, fileURL, artworkData
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Sample/Placeholder Track

extension Track {
    static let placeholder = Track(
        title: "Unknown Title",
        artist: "Unknown Artist",
        album: "Unknown Album",
        duration: 0,
        fileURL: URL(fileURLWithPath: "/")
    )
}
