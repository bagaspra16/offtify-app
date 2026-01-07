//
//  PlaylistPickerSheet.swift
//  Offtify
//
//  Sheet for selecting a playlist to add tracks to
//

import SwiftUI

struct PlaylistPickerSheet: View {
    let tracks: [Track]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playlistViewModel = PlaylistViewModel()
    @State private var showingCreatePlaylist: Bool = false
    @State private var newPlaylistName: String = ""
    @State private var selectedPlaylistId: UUID?
    @State private var showingSuccess: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add to Playlist")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.xl)
            
            Divider()
            
            // Track info
            if tracks.count == 1, let track = tracks.first {
                HStack(spacing: Theme.Spacing.lg) {
                    ArtworkView(artwork: track.artwork, size: 64, cornerRadius: 8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(2)
                        
                        Text(track.artist)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .padding(Theme.Spacing.xl)
                .background(Theme.surface)
            } else {
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Theme.gradientAccent)
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "music.note.list")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(tracks.count) tracks selected")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("Choose a playlist below")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(Theme.Spacing.xl)
                .background(Theme.surface)
            }
            
            // Create new playlist button
            Button(action: { showingCreatePlaylist = true }) {
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.gradientAccent)
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Create New Playlist")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("Add these tracks to a new playlist")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(Theme.Spacing.lg)
            }
            .buttonStyle(.plain)
            
            Divider()
            
            // Playlist list
            ScrollView {
                if playlistViewModel.playlists.isEmpty {
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.textTertiary)
                        
                        Text("No playlists yet")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                        
                        Text("Create your first playlist to get started")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(playlistViewModel.playlists) { playlist in
                            PlaylistPickerRow(
                                playlist: playlist,
                                isSelected: selectedPlaylistId == playlist.id,
                                onSelect: {
                                    selectedPlaylistId = playlist.id
                                    addToPlaylist(playlist)
                                }
                            )
                        }
                    }
                }
            }
            
            Spacer()
        }
        .frame(width: 600, height: 700)
        .background(
            ZStack {
                Color.white.opacity(BackgroundManager.shared.uiOpacity + 0.1)
                .background(.ultraThinMaterial)
            }
        )
        .sheet(isPresented: $showingCreatePlaylist) {
            CreatePlaylistWithTracksSheet(
                tracks: tracks,
                playlistViewModel: playlistViewModel,
                onCreated: {
                    showingCreatePlaylist = false
                    showSuccessAndDismiss()
                }
            )
        }
        .overlay(
            Group {
                if showingSuccess {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Added to playlist")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                        }
                        .padding(Theme.Spacing.md)
                        .background(
                            Capsule()
                                .fill(Theme.surface)
                                .shadow(color: .black.opacity(0.2), radius: 10)
                        )
                        .padding(.bottom, Theme.Spacing.xl)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        )
    }
    
    private func addToPlaylist(_ playlist: Playlist) {
        playlistViewModel.addTracks(tracks, to: playlist)
        showSuccessAndDismiss()
    }
    
    private func showSuccessAndDismiss() {
        withAnimation {
            showingSuccess = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showingSuccess = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }
    }
}

// MARK: - Playlist Picker Row

struct PlaylistPickerRow: View {
    let playlist: Playlist
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.Spacing.lg) {
                // Playlist icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.gradientAccent.opacity(0.2))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.accentPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(playlist.trackIds.count) track\(playlist.trackIds.count == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                if isHovering {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.accentPrimary)
                }
            }
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(isHovering ? Theme.surface : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(Theme.Animation.quick) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Create Playlist With Tracks Sheet

struct CreatePlaylistWithTracksSheet: View {
    let tracks: [Track]
    @ObservedObject var playlistViewModel: PlaylistViewModel
    let onCreated: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var playlistName: String = ""
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            Text("Create Playlist")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            // Name input
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Playlist Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                
                TextField("My Playlist", text: $playlistName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textPrimary)
                    .padding(Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm)
                            .fill(Theme.surface)
                    )
                    .focused($isNameFieldFocused)
            }
            
            // Track count
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundColor(Theme.textSecondary)
                
                Text("\(tracks.count) track\(tracks.count == 1 ? "" : "s") will be added")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
            }
            
            // Buttons
            HStack(spacing: Theme.Spacing.md) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.secondary)
                
                Button("Create") {
                    createPlaylist()
                }
                .buttonStyle(.primary)
                .disabled(playlistName.isEmpty)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(width: 350)
        .background(
            ZStack {
                Color.white.opacity(BackgroundManager.shared.uiOpacity + 0.1)
                .background(.ultraThinMaterial)
            }
        )
        .onAppear {
            isNameFieldFocused = true
        }
    }
    
    private func createPlaylist() {
        let playlist = playlistViewModel.createPlaylist(name: playlistName)
        playlistViewModel.addTracks(tracks, to: playlist)
        onCreated()
    }
}

#Preview {
    PlaylistPickerSheet(tracks: [
        Track(
            title: "Test Song",
            artist: "Test Artist",
            album: "Test Album",
            duration: 180,
            fileURL: URL(fileURLWithPath: "/")
        )
    ])
}
