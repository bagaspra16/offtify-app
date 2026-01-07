//
//  TrackRowView.swift
//  Offtify
//
//  Individual track row component with selection support
//

import SwiftUI

struct TrackRowView: View {
    let track: Track
    let index: Int
    let isPlaying: Bool
    var playlistViewModel: PlaylistViewModel? = nil
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    let onPlay: () -> Void
    let onAddToQueue: () -> Void
    var onToggleSelection: (() -> Void)? = nil
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Selection checkbox (in selection mode)
            if isSelectionMode {
                Button(action: {
                    onToggleSelection?()
                }) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? Theme.accentPrimary : Theme.textMuted)
                }
                .buttonStyle(.plain)
                .frame(width: 30)
            }
            
            // Track Number / Play Button
            ZStack {
                if !isSelectionMode && (isHovering || isPlaying) {
                    Button(action: onPlay) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isPlaying ? Theme.accentPrimary : Theme.textPrimary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(String(format: "%02d", index + 1))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .frame(width: 30)
            
            // Artwork
            ArtworkView(artwork: track.artwork, size: 44)
            
            // Track Info
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 14, weight: isPlaying ? .semibold : .medium))
                    .foregroundColor(isPlaying ? Theme.accentPrimary : Theme.textPrimary)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Album
            Text(track.album)
                .font(.system(size: 12))
                .foregroundColor(Theme.textTertiary)
                .lineLimit(1)
                .frame(maxWidth: 150, alignment: .leading)
            
            Spacer()
            
            // Hover Actions (not in selection mode)
            if !isSelectionMode && isHovering {
                HStack(spacing: Theme.Spacing.xs) {
                    Button(action: onAddToQueue) {
                        Image(systemName: "text.badge.plus")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Add to queue")
                }
            }
            
            // Duration
            Text(track.formattedDuration)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Theme.textTertiary)
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .fill(
                    isSelected ? Theme.accentPrimary.opacity(0.15) :
                    isPlaying ? Theme.accentPrimary.opacity(0.1) :
                    (isHovering ? Theme.surface : Color.clear)
                )
        )
        .onHover { hovering in
            withAnimation(Theme.Animation.quick) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            if isSelectionMode {
                onToggleSelection?()
            } else {
                onPlay()
            }
        }
        // Drag & Drop
        .onDrag {
            NSItemProvider(object: track.id.uuidString as NSString)
        }
        .contextMenu {
            if !isSelectionMode {
                Button(action: onPlay) {
                    Label("Play", systemImage: "play")
                }
                
                Button(action: onAddToQueue) {
                    Label("Add to Queue", systemImage: "text.plus")
                }
                
                Divider()
                
                if let playlistViewModel = playlistViewModel {
                    Menu("Add to Playlist") {
                        Button(action: {
                            playlistViewModel.showCreatePlaylist()
                        }) {
                            Label("New Playlist", systemImage: "plus")
                        }
                        
                        if !playlistViewModel.playlists.isEmpty {
                            Divider()
                            
                            ForEach(playlistViewModel.playlists) { playlist in
                                Button(action: {
                                    playlistViewModel.addTrack(track, to: playlist)
                                }) {
                                    Text(playlist.name)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Artwork View

struct ArtworkView: View {
    let artwork: NSImage?
    var size: CGFloat = 44
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        Group {
            if let artwork = artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Theme.accentMuted, Theme.accentDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.35, weight: .light))
                        .foregroundColor(Theme.textTertiary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack(spacing: 0) {
        TrackRowView(
            track: Track(
                title: "Bohemian Rhapsody",
                artist: "Queen",
                album: "A Night at the Opera",
                duration: 354,
                fileURL: URL(fileURLWithPath: "/")
            ),
            index: 0,
            isPlaying: false,
            onPlay: {},
            onAddToQueue: {}
        )
        
        TrackRowView(
            track: Track(
                title: "Stairway to Heaven",
                artist: "Led Zeppelin",
                album: "Led Zeppelin IV",
                duration: 482,
                fileURL: URL(fileURLWithPath: "/")
            ),
            index: 1,
            isPlaying: true,
            onPlay: {},
            onAddToQueue: {}
        )
        
        TrackRowView(
            track: Track(
                title: "Hotel California",
                artist: "Eagles",
                album: "Hotel California",
                duration: 391,
                fileURL: URL(fileURLWithPath: "/")
            ),
            index: 2,
            isPlaying: false,
            isSelectionMode: true,
            isSelected: true,
            onPlay: {},
            onAddToQueue: {},
            onToggleSelection: {}
        )
    }
    .padding()
    .background(Theme.backgroundPrimary)
}
