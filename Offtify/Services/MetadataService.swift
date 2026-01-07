//
//  MetadataService.swift
//  Offtify
//
//  Extracts metadata from audio files using AVFoundation
//

import Foundation
import AVFoundation
import AppKit

/// Service for extracting metadata from audio files
final class MetadataService {
    
    // MARK: - Singleton
    
    static let shared = MetadataService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Extract metadata from an audio file
    /// - Parameter url: The URL of the audio file
    /// - Returns: A Track object with extracted metadata
    func extractMetadata(from url: URL) async -> Track? {
        let asset = AVAsset(url: url)
        
        do {
            // Load metadata asynchronously
            let metadata = try await asset.load(.metadata)
            let duration = try await asset.load(.duration)
            
            var title = url.deletingPathExtension().lastPathComponent
            var artist = "Unknown Artist"
            var album = "Unknown Album"
            var artworkData: Data?
            
            // Parse metadata items
            for item in metadata {
                guard let key = item.commonKey?.rawValue else { continue }
                
                switch key {
                case "title":
                    if let value = try? await item.load(.stringValue) {
                        title = value
                    }
                case "artist":
                    if let value = try? await item.load(.stringValue) {
                        artist = value
                    }
                case "albumName":
                    if let value = try? await item.load(.stringValue) {
                        album = value
                    }
                case "artwork":
                    if let data = try? await item.load(.dataValue) {
                        artworkData = data
                    }
                default:
                    break
                }
            }
            
            // Try to get artwork from different sources if not found
            if artworkData == nil {
                artworkData = await extractArtwork(from: asset, metadata: metadata)
            }
            
            let durationSeconds = CMTimeGetSeconds(duration)
            
            return Track(
                title: title,
                artist: artist,
                album: album,
                duration: durationSeconds.isNaN ? 0 : durationSeconds,
                fileURL: url,
                artworkData: artworkData
            )
        } catch {
            print("Failed to extract metadata from \(url.lastPathComponent): \(error)")
            
            // Return basic track with filename as title
            return Track(
                title: url.deletingPathExtension().lastPathComponent,
                artist: "Unknown Artist",
                album: "Unknown Album",
                duration: 0,
                fileURL: url,
                artworkData: nil
            )
        }
    }
    
    /// Extract multiple tracks from URLs
    /// - Parameter urls: Array of audio file URLs
    /// - Returns: Array of Track objects
    func extractMetadata(from urls: [URL]) async -> [Track] {
        var tracks: [Track] = []
        
        for url in urls {
            if let track = await extractMetadata(from: url) {
                tracks.append(track)
            }
        }
        
        return tracks
    }
    
    // MARK: - Private Methods
    
    private func extractArtwork(from asset: AVAsset, metadata: [AVMetadataItem]) async -> Data? {
        // Try common artwork keys
        let artworkKeys = [
            AVMetadataKey.commonKeyArtwork,
            AVMetadataKey.id3MetadataKeyAttachedPicture,
            AVMetadataKey.iTunesMetadataKeyCoverArt
        ]
        
        for key in artworkKeys {
            let items = AVMetadataItem.metadataItems(from: metadata, withKey: key, keySpace: nil)
            for item in items {
                if let data = try? await item.load(.dataValue) {
                    return data
                }
            }
        }
        
        // Try ID3 specific lookup
        let id3Items = AVMetadataItem.metadataItems(
            from: metadata,
            filteredByIdentifier: .id3MetadataAttachedPicture
        )
        
        for item in id3Items {
            if let data = try? await item.load(.dataValue) {
                return data
            }
        }
        
        return nil
    }
    
    /// Generate a placeholder artwork image
    /// - Parameters:
    ///   - title: Track title for generating unique colors
    ///   - size: Size of the image
    /// - Returns: Generated NSImage
    func generatePlaceholderArtwork(for title: String, size: CGSize = CGSize(width: 200, height: 200)) -> NSImage {
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Create gradient based on title hash
        let hash = abs(title.hashValue)
        let hue1 = CGFloat(hash % 360) / 360.0
        let hue2 = CGFloat((hash + 60) % 360) / 360.0
        
        let color1 = NSColor(hue: hue1, saturation: 0.6, brightness: 0.4, alpha: 1.0)
        let color2 = NSColor(hue: hue2, saturation: 0.5, brightness: 0.3, alpha: 1.0)
        
        let gradient = NSGradient(colors: [color1, color2])
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 45)
        
        // Draw music note icon
        let noteFont = NSFont.systemFont(ofSize: size.width * 0.4, weight: .light)
        let noteString = "♪"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: noteFont,
            .foregroundColor: NSColor.white.withAlphaComponent(0.3)
        ]
        
        let noteSize = noteString.size(withAttributes: attributes)
        let notePoint = NSPoint(
            x: (size.width - noteSize.width) / 2,
            y: (size.height - noteSize.height) / 2
        )
        noteString.draw(at: notePoint, withAttributes: attributes)
        
        image.unlockFocus()
        
        return image
    }
}
