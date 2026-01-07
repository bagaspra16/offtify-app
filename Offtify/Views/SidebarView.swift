//
//  SidebarView.swift
//  Offtify
//
//  Navigation sidebar with glassmorphism design
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var libraryViewModel: LibraryViewModel
    @ObservedObject var playerViewModel: PlayerViewModel
    @ObservedObject var playlistViewModel: PlaylistViewModel
    @Binding var selectedDestination: NavigationDestination
    @Binding var showingSettings: Bool
    
    @State private var isHoveringRescan: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo and App Name
            logoSection
            
            // Search Field
            searchField
            
            Divider()
                .background(Theme.textMuted)
                .padding(.horizontal, Theme.Spacing.md)
            
            // Navigation Menu
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    // Main Navigation
                    menuSection(title: "Menu", items: [.home, .library])
                    
                    // Library Section
                    menuSection(title: "Library", items: [.albums, .artists])
                    
                    // Playlists Section
                    playlistsSection
                    
                    // Recently Played Section
                    if !libraryViewModel.recentlyPlayed.isEmpty {
                        recentlyPlayedSection
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
            }
            
            Spacer()
            
            // Library Info Footer
            libraryInfoFooter
        }
        .frame(minWidth: 230, idealWidth: 250, maxWidth: 290)
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // App Icon
            ZStack {
                Circle()
                    .fill(Theme.gradientAccent)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "music.note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Offtify")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Local Music Player")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textTertiary)
            }
            
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.xl)
        .padding(.bottom, Theme.Spacing.lg)
    }
    
    // MARK: - Search Field
    
    private var searchField: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(Theme.textTertiary)
            
            TextField("Search...", text: $libraryViewModel.searchQuery)
                .textFieldStyle(.plain)
                .foregroundColor(Theme.textPrimary)
                .font(.system(size: 14))
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.md)
    }
    
    // MARK: - Menu Section
    
    private func menuSection(title: String, items: [NavigationDestination]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textMuted)
                .textCase(.uppercase)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xxs)
            
            ForEach(items) { destination in
                NavigationRow(
                    destination: destination,
                    isSelected: selectedDestination == destination
                ) {
                    selectedDestination = destination
                }
            }
        }
    }
    
    // MARK: - Playlists Section
    
    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            HStack {
                Text("PLAYLISTS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textMuted)
                
                Spacer()
                
                Button(action: {
                    selectedDestination = .playlists
                    // Delay slightly to allow view transition before showing sheet
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        playlistViewModel.showCreatePlaylist()
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xxs)
            
            // All Playlists Link
            NavigationRow(
                destination: .playlists,
                isSelected: selectedDestination == .playlists
            ) {
                selectedDestination = .playlists
            }
            
            // Individual Playlists
            ForEach(playlistViewModel.playlists) { playlist in
                PlaylistSidebarRow(
                    playlist: playlist,
                    isSelected: false // TODO: Handle specific playlist selection state if needed
                ) {
                    selectedDestination = .playlists
                    playlistViewModel.selectPlaylist(playlist)
                }
            }
        }
    }
    
    // MARK: - Recently Played Section
    
    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text("Recently Played")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textMuted)
                .textCase(.uppercase)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xxs)
            
            ForEach(libraryViewModel.recentlyPlayed.prefix(5)) { track in
                RecentTrackRow(track: track) {
                    playerViewModel.play(track, in: libraryViewModel.tracks)
                }
            }
        }
    }
    
    // MARK: - Library Info Footer
    
    private var libraryInfoFooter: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Divider()
                .background(Theme.textMuted)
            
            if libraryViewModel.hasLoadedLibrary {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(libraryViewModel.trackCount) tracks")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                        
                        Text(libraryViewModel.libraryPath)
                            .font(.system(size: 10))
                            .foregroundColor(Theme.textTertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        libraryViewModel.rescanLibrary()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                            .foregroundColor(isHoveringRescan ? Theme.accentPrimary : Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(Theme.Animation.quick) {
                            isHoveringRescan = hovering
                        }
                    }
                }
            } else {
                Button(action: {
                    libraryViewModel.selectMusicFolder()
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Select Music Folder")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Theme.accentPrimary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .background(Theme.textMuted)
            
            // Settings Button
            Button(action: { showingSettings = true }) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                    Text("Settings")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                }
                .foregroundColor(Theme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
    }
}

// MARK: - Navigation Row

struct NavigationRow: View {
    let destination: NavigationDestination
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: destination.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? Theme.accentPrimary : Theme.textSecondary)
                    .frame(width: 20)
                
                Text(destination.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(isSelected ? Theme.accentPrimary.opacity(0.15) : (isHovering ? Theme.surface : Color.clear))
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

// MARK: - Recent Track Row

struct RecentTrackRow: View {
    let track: Track
    let action: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                // Artwork
                Group {
                    if let artwork = track.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ZStack {
                            Theme.accentMuted
                            Image(systemName: "music.note")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(track.title)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.vertical, Theme.Spacing.xxs)
            .padding(.horizontal, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
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



// MARK: - Playlist Sidebar Row

struct PlaylistSidebarRow: View {
    let playlist: Playlist
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? Theme.accentPrimary : Theme.textSecondary)
                    .frame(width: 20)
                
                Text(playlist.name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textSecondary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(isSelected ? Theme.accentPrimary.opacity(0.15) : (isHovering ? Theme.surface : Color.clear))
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

#Preview {
    SidebarView(
        libraryViewModel: LibraryViewModel(),
        playerViewModel: PlayerViewModel(),
        playlistViewModel: PlaylistViewModel(),
        selectedDestination: .constant(.library),
        showingSettings: .constant(false)
    )
    .frame(height: 600)
}
