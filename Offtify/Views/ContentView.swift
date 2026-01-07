//
//  ContentView.swift
//  Offtify
//
//  Main content view with navigation split
//

import SwiftUI

struct ContentView: View {
    @StateObject private var libraryViewModel = LibraryViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var playlistViewModel = PlaylistViewModel()
    
    @State private var selectedDestination: NavigationDestination = .library
    @State private var showingFullPlayer: Bool = false
    @State private var showingFullScreenPlayer: Bool = false
    @State private var showingSettings: Bool = false

    
    var body: some View {
        ZStack {
            // Custom Background Layer
            CustomBackgroundView()
            
            ZStack(alignment: .bottom) {
                // Main Content
                HStack(spacing: 0) {
                    // Sidebar
                    SidebarView(
                        libraryViewModel: libraryViewModel,
                        playerViewModel: playerViewModel,
                        playlistViewModel: playlistViewModel,
                        selectedDestination: $selectedDestination,
                        showingSettings: $showingSettings
                    )
                    .background(
                        ZStack {
                            Color.white.opacity(BackgroundManager.shared.uiOpacity)
                            .background(.ultraThinMaterial)
                        }
                        .padding(.bottom, -10)
                    )
                    
                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(BackgroundManager.shared.uiOpacity))
                        .background(.ultraThinMaterial)
                        .overlay(
                            Rectangle()
                                .fill(Theme.textMuted.opacity(0.15))
                        )
                        .frame(width: 1)
                        .padding(.bottom, -10)
                    
                    // Main Content Area
                    MainContentViewWrapper(
                        libraryViewModel: libraryViewModel,
                        playerViewModel: playerViewModel,
                        playlistViewModel: playlistViewModel,
                        selectedDestination: selectedDestination
                    )
                        .background(
                            ZStack {
                                // Glassmorphism background for main content
                                Color.white.opacity(BackgroundManager.shared.uiOpacity)
                                
                                // Blur effect
                                .background(.ultraThinMaterial)
                            }
                            .padding(.bottom, -10)
                        )
                }
                .padding(.bottom, playerViewModel.hasCurrentTrack ? 96 : 0)
                
                // Mini Player
                if playerViewModel.hasCurrentTrack {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        MiniPlayerView(
                            playerViewModel: playerViewModel,
                            onArtworkTap: {
                                withAnimation(Theme.Animation.smooth) {
                                    showingFullScreenPlayer = true
                                }
                            }
                        )
                        .onTapGesture {
                            // Single tap now opens the immersive player directly
                            withAnimation(Theme.Animation.smooth) {
                                showingFullScreenPlayer = true
                            }
                        }
                    }
                }
            }
            .blur(radius: showingFullScreenPlayer ? 10 : 0)
            
            // Immersive Full Screen Player Overlay
            if showingFullScreenPlayer {
                FullScreenPlayerView(
                    playerViewModel: playerViewModel,
                    isPresented: $showingFullScreenPlayer
                )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity.combined(with: .scale(scale: 1.1))
                    ))
                    .zIndex(100)
            }
        }
        // Removed default background to allow CustomBackgroundView to show
        .onAppear {
            playerViewModel.setLibraryViewModel(libraryViewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("addTrackToPlaylist"))) { notification in
            guard let userInfo = notification.userInfo,
                  let trackId = userInfo["trackId"] as? UUID,
                  let playlistId = userInfo["playlistId"] as? UUID,
                  let track = libraryViewModel.track(byId: trackId),
                  let playlist = playlistViewModel.playlists.first(where: { $0.id == playlistId }) else {
                return
            }
            
            playlistViewModel.addTrack(track, to: playlist)
        }
        .onChange(of: selectedDestination) { newValue in
            libraryViewModel.selectedDestination = newValue
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .presentationDetents([.large])
        }

    }
    
    // Optimized Main Content Wrapper to prevent redraws on player progress
    private struct MainContentViewWrapper: View {
        @ObservedObject var libraryViewModel: LibraryViewModel
        @ObservedObject var playerViewModel: PlayerViewModel // Only observes track changes, not progress
        @ObservedObject var playlistViewModel: PlaylistViewModel
        let selectedDestination: NavigationDestination
        
        var body: some View {
            switch selectedDestination {
            case .home:
                HomeView(libraryViewModel: libraryViewModel, playerViewModel: playerViewModel)
            case .library:
                LibraryView(libraryViewModel: libraryViewModel, playerViewModel: playerViewModel, playlistViewModel: playlistViewModel)
            case .albums:
                AlbumsView(libraryViewModel: libraryViewModel, playerViewModel: playerViewModel)
            case .artists:
                ArtistsView(libraryViewModel: libraryViewModel, playerViewModel: playerViewModel)
            case .playlists:
                PlaylistsContentView(
                    libraryViewModel: libraryViewModel,
                    playerViewModel: playerViewModel,
                    playlistViewModel: playlistViewModel
                )
            }
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @ObservedObject var libraryViewModel: LibraryViewModel
    @ObservedObject var playerViewModel: PlayerViewModel
    @State private var showingClearConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                // Welcome Header
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(getGreeting())
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                    
                    Text("Welcome to Offtify")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.xl)
                
                // Quick Actions
                if libraryViewModel.hasLoadedLibrary {
                    quickActionsSection
                }
                
                // Recently Played
                if !libraryViewModel.recentlyPlayed.isEmpty {
                    recentlyPlayedSection
                }
                
                // Library Stats
                if libraryViewModel.hasLoadedLibrary {
                    statsSection
                }
                
                Spacer(minLength: 120)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Clear Library?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                libraryViewModel.clearAllMusic()
            }
        } message: {
            Text("This will remove all songs from Offtify. Your files will NOT be deleted from your computer.")
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, Theme.Spacing.lg)
            
            HStack(spacing: Theme.Spacing.md) {
                QuickActionCard(
                    icon: "play.fill",
                    title: "Play All",
                    subtitle: "\(libraryViewModel.trackCount) tracks"
                ) {
                    playerViewModel.playAll(libraryViewModel.tracks)
                }
                
                QuickActionCard(
                    icon: "shuffle",
                    title: "Shuffle",
                    subtitle: "Random mix"
                ) {
                    playerViewModel.toggleShuffle()
                    playerViewModel.playAll(libraryViewModel.tracks)
                }
                
                QuickActionCard(
                    icon: "arrow.clockwise",
                    title: "Rescan",
                    subtitle: "Update library"
                ) {
                    libraryViewModel.rescanLibrary()
                }
                                QuickActionCard(
                            icon: "plus.circle",
                            title: "Import Music",
                            subtitle: "Add files/folders",
                            action: {
                                libraryViewModel.importMusic()
                            }
                        )
                        
                        QuickActionCard(
                            icon: "trash",
                            title: "Clear Library",
                            subtitle: "Remove all songs",
                            isDestructive: true,
                            action: {
                                showingClearConfirmation = true
                            }
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
        }
    }
    
    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Recently Played")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, Theme.Spacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(libraryViewModel.recentlyPlayed.prefix(10)) { track in
                        RecentTrackCard(track: track) {
                            playerViewModel.play(track, in: libraryViewModel.tracks)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Your Library")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, Theme.Spacing.lg)
            
            HStack(spacing: Theme.Spacing.md) {
                StatCard(value: "\(libraryViewModel.trackCount)", label: "Tracks")
                StatCard(value: "\(libraryViewModel.uniqueAlbums.count)", label: "Albums")
                StatCard(value: "\(libraryViewModel.uniqueArtists.count)", label: "Artists")
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isDestructive ? .red : Theme.accentPrimary)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(isDestructive ? Color.red.opacity(0.1) : Theme.accentPrimary.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isDestructive ? .red : Theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
            }
            .padding(Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .fill(isHovering ? Theme.surface : Theme.backgroundSecondary)
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

// MARK: - Recent Track Card

struct RecentTrackCard: View {
    let track: Track
    let action: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ArtworkView(artwork: track.artwork, size: 120, cornerRadius: 12)
                    .overlay(
                        Group {
                            if isHovering {
                                ZStack {
                                    Color.black.opacity(0.4)
                                    
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(width: 120)
            .scaleEffect(isHovering ? Theme.Animation.hoverScale : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(Theme.Animation.quick) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.accentPrimary)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
}

// MARK: - Albums View

struct AlbumsView: View {
    @ObservedObject var libraryViewModel: LibraryViewModel
    @ObservedObject var playerViewModel: PlayerViewModel
    
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: Theme.Spacing.lg)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text("Albums")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.lg)
                
                if libraryViewModel.hasLoadedLibrary {
                    LazyVGrid(columns: columns, spacing: Theme.Spacing.lg) {
                        ForEach(libraryViewModel.uniqueAlbums, id: \.self) { album in
                            AlbumCard(
                                album: album,
                                tracks: libraryViewModel.tracks(forAlbum: album)
                            ) {
                                let albumTracks = libraryViewModel.tracks(forAlbum: album)
                                if let firstTrack = albumTracks.first {
                                    playerViewModel.play(firstTrack, in: albumTracks)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                } else {
                    emptyStateView
                }
                
                Spacer(minLength: 120)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "square.stack")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Theme.textTertiary)
            
            Text("No Albums")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct AlbumCard: View {
    let album: String
    let tracks: [Track]
    let action: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Album Artwork
                ArtworkView(
                    artwork: tracks.first?.artwork,
                    size: 160,
                    cornerRadius: 12
                )
                .overlay(
                    Group {
                        if isHovering {
                            ZStack {
                                Color.black.opacity(0.4)
                                
                                Image(systemName: "play.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(album)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(tracks.count) tracks")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .scaleEffect(isHovering ? Theme.Animation.hoverScale : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(Theme.Animation.quick) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Artists View

struct ArtistsView: View {
    @ObservedObject var libraryViewModel: LibraryViewModel
    @ObservedObject var playerViewModel: PlayerViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text("Artists")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.lg)
                
                if libraryViewModel.hasLoadedLibrary {
                    LazyVStack(spacing: 0) {
                        ForEach(libraryViewModel.uniqueArtists, id: \.self) { artist in
                            ArtistRow(
                                artist: artist,
                                trackCount: libraryViewModel.tracks(forArtist: artist).count
                            ) {
                                let artistTracks = libraryViewModel.tracks(forArtist: artist)
                                if let firstTrack = artistTracks.first {
                                    playerViewModel.play(firstTrack, in: artistTracks)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                } else {
                    emptyStateView
                }
                
                Spacer(minLength: 120)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "person.2")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Theme.textTertiary)
            
            Text("No Artists")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

struct ArtistRow: View {
    let artist: String
    let trackCount: Int
    let action: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.gradientAccent)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(artist)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("\(trackCount) tracks")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                }
                
                Spacer()
                
                if isHovering {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.accentPrimary)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
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

// MARK: - Playlists Content View

struct PlaylistsContentView: View {
    @ObservedObject var libraryViewModel: LibraryViewModel
    @ObservedObject var playerViewModel: PlayerViewModel
    @ObservedObject var playlistViewModel: PlaylistViewModel
    
    @State private var selectedPlaylistId: UUID?
    @State private var showingCreateSheet: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Playlists")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button(action: { showingCreateSheet = true }) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "plus")
                        Text("New Playlist")
                    }
                    .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.primary)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.md)
            
            if playlistViewModel.playlists.isEmpty {
                emptyStateView
            } else {
                // Split view: playlist list and tracks
                HStack(spacing: 0) {
                    // Playlist List
                    playlistList
                    
                    Rectangle()
                        .fill(Theme.textMuted.opacity(0.2))
                        .frame(width: 1)
                    
                    // Playlist Tracks
                    if let selectedId = selectedPlaylistId,
                       let playlist = playlistViewModel.playlists.first(where: { $0.id == selectedId }) {
                        playlistTracksView(playlist: playlist)
                    } else {
                        noSelectionView
                    }
                }
            }
            
            Spacer(minLength: 120)
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreatePlaylistSheet(playlistViewModel: playlistViewModel)
        }
    }
    
    private var playlistList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.xs) {
                ForEach(playlistViewModel.playlists) { playlist in
                    PlaylistRowItem(
                        playlist: playlist,
                        isSelected: selectedPlaylistId == playlist.id,
                        onSelect: { selectedPlaylistId = playlist.id },
                        onDelete: { playlistViewModel.deletePlaylist(playlist) }
                    )
                }
            }
            .padding(Theme.Spacing.md)
        }
        .frame(width: 250)
    }
    
    private func playlistTracksView(playlist: Playlist) -> some View {
        let tracks = playlistViewModel.getTracks(for: playlist, from: libraryViewModel.tracks)
        
        return VStack(alignment: .leading, spacing: 0) {
            // Playlist header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("\(tracks.count) tracks")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                if !tracks.isEmpty {
                    Button(action: {
                        playerViewModel.playAll(tracks)
                    }) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "play.fill")
                            Text("Play All")
                        }
                        .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.primary)
                }
            }
            .padding(Theme.Spacing.md)
            
            if tracks.isEmpty {
                VStack(spacing: Theme.Spacing.md) {
                    Spacer()
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textTertiary)
                    Text("No tracks in this playlist")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                    Text("Add tracks from your library")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                            TrackRowView(
                                track: track,
                                index: index,
                                isPlaying: playerViewModel.currentTrack?.id == track.id,
                                onPlay: { playerViewModel.play(track, in: tracks) },
                                onAddToQueue: { playerViewModel.addToQueue(track) }
                            )
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.sm)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var noSelectionView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(Theme.textTertiary)
            Text("Select a playlist")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "music.note.list")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(Theme.textTertiary)
            
            VStack(spacing: Theme.Spacing.xs) {
                Text("No Playlists Yet")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                
                Text("Create your first playlist to organize your music")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textTertiary)
            }
            
            Button(action: { showingCreateSheet = true }) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "plus")
                    Text("Create Playlist")
                }
                .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(.primary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Playlist Row Item

struct PlaylistRowItem: View {
    let playlist: Playlist
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.Spacing.sm) {
                // Playlist icon/artwork
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.gradientAccent)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "music.note.list")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(playlist.trackCount) tracks")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textTertiary)
                }
                
                Spacer()
                
                if isHovering {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(isSelected ? Theme.accentPrimary.opacity(0.2) : (isHovering ? Theme.surface : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        // Drag & Drop
        .onDrop(of: [.text], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            
            provider.loadObject(ofClass: NSString.self) { item, error in
                guard let uuidString = item as? String,
                      let trackId = UUID(uuidString: uuidString) else { return }
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: Notification.Name("addTrackToPlaylist"),
                        object: nil,
                        userInfo: ["trackId": trackId, "playlistId": playlist.id]
                    )
                }
            }
            return true
        }
    }
}

// MARK: - Create Playlist Sheet

struct CreatePlaylistSheet: View {
    @ObservedObject var playlistViewModel: PlaylistViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var playlistName: String = ""
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("Create New Playlist")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            TextField("Playlist Name", text: $playlistName)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(Theme.Spacing.sm)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
            
            HStack(spacing: Theme.Spacing.md) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.secondary)
                
                Button("Create") {
                    let name = playlistName.isEmpty ? "New Playlist" : playlistName
                    _ = playlistViewModel.createPlaylist(name: name)
                    dismiss()
                }
                .buttonStyle(.primary)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(width: 350)
        .background(Theme.backgroundSecondary)
    }
}

#Preview {
    ContentView()
        .frame(width: 1200, height: 800)
}
