//
//  LibraryView.swift
//  Offtify
//
//  Main library content view with track list and multi-select
//

import SwiftUI

struct LibraryView: View {
    @ObservedObject var libraryViewModel: LibraryViewModel
    @ObservedObject var playerViewModel: PlayerViewModel
    var playlistViewModel: PlaylistViewModel? = nil
    
    @State private var isSelectionMode: Bool = false
    @State private var selectedTrackIds: Set<UUID> = []
    @State private var showingPlaylistPicker: Bool = false
    
    private var selectedTracks: [Track] {
        libraryViewModel.filteredTracks.filter { selectedTrackIds.contains($0.id) }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                if libraryViewModel.isLoading {
                    loadingView
                } else if !libraryViewModel.hasLoadedLibrary {
                    emptyStateView
                } else if libraryViewModel.filteredTracks.isEmpty {
                    noResultsView
                } else {
                    trackListView
                }
            }
            
            // Floating toolbar for selected tracks
            if isSelectionMode && !selectedTrackIds.isEmpty {
                selectionToolbar
            }
        }
        .sheet(isPresented: $showingPlaylistPicker) {
            PlaylistPickerSheet(tracks: selectedTracks)
                .onDisappear {
                    // Clear selection after adding to playlist
                    selectedTrackIds.removeAll()
                    isSelectionMode = false
                }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(getHeaderTitle())
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    
                    if libraryViewModel.hasLoadedLibrary {
                        if isSelectionMode && !selectedTrackIds.isEmpty {
                            Text("\(selectedTrackIds.count) selected")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.accentPrimary)
                        } else {
                            Text("\(libraryViewModel.filteredTracks.count) tracks")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                if libraryViewModel.hasLoadedLibrary && !libraryViewModel.filteredTracks.isEmpty {
                    // Selection mode toggle
                    Button(action: {
                        withAnimation {
                            isSelectionMode.toggle()
                            if !isSelectionMode {
                                selectedTrackIds.removeAll()
                            }
                        }
                    }) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.system(size: 12))
                            Text(isSelectionMode ? "Done" : "Select")
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    if !isSelectionMode {
                        // Play All Button
                        Button(action: {
                            playerViewModel.playAll(libraryViewModel.filteredTracks)
                        }) {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12))
                                Text("Play All")
                                    .font(.system(size: 13, weight: .medium))
                            }
                        }
                        .buttonStyle(.primary)
                        
                        // Shuffle Button
                        Button(action: {
                            playerViewModel.toggleShuffle()
                            playerViewModel.playAll(libraryViewModel.filteredTracks)
                        }) {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 12))
                                Text("Shuffle")
                                    .font(.system(size: 13, weight: .medium))
                            }
                        }
                        .buttonStyle(.secondary)
                    }
                }
            }
            
            // Column Headers
            if libraryViewModel.hasLoadedLibrary && !libraryViewModel.filteredTracks.isEmpty {
                columnHeaders
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.md)
    }
    
    private var columnHeaders: some View {
        HStack(spacing: Theme.Spacing.md) {
            if isSelectionMode {
                Text("")
                    .frame(width: 30, alignment: .leading)
            }
            
            Text("#")
                .frame(width: 30, alignment: .leading)
            
            Text("")
                .frame(width: 44)
            
            Text("TITLE")
            
            Spacer()
            
            Text("ALBUM")
                .frame(maxWidth: 150, alignment: .leading)
            
            Spacer()
            
            Image(systemName: "clock")
                .frame(width: 44, alignment: .trailing)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(Theme.textMuted)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xs)
    }
    
    // MARK: - Track List
    
    private var trackListView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 0) {
                ForEach(Array(libraryViewModel.filteredTracks.enumerated()), id: \.element.id) { index, track in
                    TrackRowView(
                        track: track,
                        index: index,
                        isPlaying: playerViewModel.currentTrack?.id == track.id,
                        playlistViewModel: playlistViewModel,
                        isSelectionMode: isSelectionMode,
                        isSelected: selectedTrackIds.contains(track.id),
                        onPlay: {
                            if isSelectionMode {
                                toggleSelection(track.id)
                            } else {
                                playerViewModel.play(track, in: libraryViewModel.filteredTracks)
                            }
                        },
                        onAddToQueue: {
                            playerViewModel.addToQueue(track)
                        },
                        onToggleSelection: {
                            toggleSelection(track.id)
                        }
                    )
                }
            }
            .padding(.bottom, isSelectionMode && !selectedTrackIds.isEmpty ? 180 : 120)
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
    
    // MARK: - Selection Toolbar
    
    private var selectionToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: Theme.Spacing.lg) {
                // Selection info
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(selectedTrackIds.count) track\(selectedTrackIds.count == 1 ? "" : "s") selected")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Choose an action")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: Theme.Spacing.md) {
                    // Select All / Deselect All
                    Button(action: {
                        if selectedTrackIds.count == libraryViewModel.filteredTracks.count {
                            selectedTrackIds.removeAll()
                        } else {
                            selectedTrackIds = Set(libraryViewModel.filteredTracks.map { $0.id })
                        }
                    }) {
                        Text(selectedTrackIds.count == libraryViewModel.filteredTracks.count ? "Deselect All" : "Select All")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.secondary)
                    
                    // Play Selected
                    Button(action: {
                        playerViewModel.playAll(selectedTracks)
                        selectedTrackIds.removeAll()
                        isSelectionMode = false
                    }) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "play.fill")
                            Text("Play")
                        }
                        .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.secondary)
                    
                    // Add to Playlist
                    Button(action: {
                        showingPlaylistPicker = true
                    }) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "plus")
                            Text("Add to Playlist")
                        }
                        .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.primary)
                }
            }
            .padding(Theme.Spacing.lg)
            .background(
                Theme.surface
                    .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
            )
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.accentPrimary))
            
            VStack(spacing: Theme.Spacing.xs) {
                Text("Scanning Library")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Extracting metadata from audio files...")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(Theme.gradientAccent.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Theme.accentPrimary)
            }
            
            VStack(spacing: Theme.Spacing.sm) {
                Text("No Music Library")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Select a folder containing your music files\nto get started")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                libraryViewModel.selectMusicFolder()
            }) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "folder")
                        .font(.system(size: 14))
                    Text("Select Music Folder")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .buttonStyle(.primary)
            
            // Supported Formats
            VStack(spacing: Theme.Spacing.xs) {
                Text("Supported Formats")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textTertiary)
                
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(["MP3", "FLAC", "WAV", "M4A", "AAC"], id: \.self) { format in
                        Text(format)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xxs)
                            .background(Theme.surface)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.top, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - No Results
    
    private var noResultsView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Theme.textTertiary)
            
            VStack(spacing: Theme.Spacing.xs) {
                Text("No Results")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                
                Text("No tracks match '\(libraryViewModel.searchQuery)'")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Button(action: {
                libraryViewModel.searchQuery = ""
            }) {
                Text("Clear Search")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private func toggleSelection(_ trackId: UUID) {
        if selectedTrackIds.contains(trackId) {
            selectedTrackIds.remove(trackId)
        } else {
            selectedTrackIds.insert(trackId)
        }
    }
    
    private func getHeaderTitle() -> String {
        switch libraryViewModel.selectedDestination {
        case .home:
            return "Home"
        case .library:
            return "Library"
        case .albums:
            return "Albums"
        case .artists:
            return "Artists"
        case .playlists:
            return "Playlists"
        }
    }
}

#Preview {
    LibraryView(
        libraryViewModel: LibraryViewModel(),
        playerViewModel: PlayerViewModel()
    )
    .frame(width: 800, height: 600)
}
