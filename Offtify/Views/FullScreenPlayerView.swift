//
//  FullScreenPlayerView.swift
//  Offtify
//
//  Immersive full-screen player with Spotify-style design
//

import SwiftUI

struct FullScreenPlayerView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @ObservedObject var playerProgress: PlayerProgress
    @Binding var isPresented: Bool
    
    @State private var dominantColors: ColorExtractor.DominantColors = .default
    @State private var isDraggingProgress: Bool = false
    @State private var dragProgress: Double = 0
    @State private var showingPlaylistPicker: Bool = false
    
    init(playerViewModel: PlayerViewModel, isPresented: Binding<Bool>) {
        self.playerViewModel = playerViewModel
        self.playerProgress = playerViewModel.progress
        self._isPresented = isPresented
    }
    
    private var currentProgress: Double {
        isDraggingProgress ? dragProgress : playerProgress.progress
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 0: Blurred background
                backgroundView
                
                // Layer 1: Centered content (Artwork & Text)
                // This is placed independently so it sits EXACTLY in the center of the screen
                VStack(spacing: geometry.size.height * 0.04) {
                    if let track = playerViewModel.currentTrack {
                        // Dynamic artwork size
                        // Using slightly smaller max height (40%) to ensure clearance for controls even on small screens
                        let size = min(geometry.size.height * 0.40, geometry.size.width * 0.8)
                        
                        ArtworkView(artwork: track.artwork, size: size, cornerRadius: 20)
                            .shadow(color: .black.opacity(0.5), radius: 50, x: 0, y: 30)
                        
                        // Track info
                        VStack(spacing: Theme.Spacing.xs) {
                            Text(track.title)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                            
                            Text(track.artist)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, Theme.Spacing.xl)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .offset(y: -280) // Adjusted visual correction upwards as requested
                
                // Layer 2: UI Overlays (Top Bar & Bottom Controls)
                VStack(spacing: 0) {
                    // Top Bar (Pinned Top)
                    topBar
                        .padding(.top, Theme.Spacing.md)
                        .frame(height: 60)
                    
                    Spacer()
                    
                    // Bottom Controls (Pinned Bottom)
                    VStack(spacing: Theme.Spacing.lg) {
                        progressSection
                        controlsSection
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 40)
                    .background(
                        // Add a subtle gradient behind controls to ensure readability if artwork is large
                        LinearGradient(
                            colors: [.black.opacity(0.0), .black.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 200)
                        .offset(y: 40)
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(true) // Ensure this layer receives touches
            }
        }
        .background(Color.black)
        .onAppear {
            updateColors()
        }
        .onChange(of: playerViewModel.currentTrack?.id) { _ in
            updateColors()
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            // Base dark color
            Color(hex: "0B0F1A")
            
            // Blurred artwork background
            if let track = playerViewModel.currentTrack, let artwork = track.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 100)
                    .scaleEffect(1.5)
                    .opacity(0.4)
            }
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Spacer()
            
            // Exit full-screen button (down arrow)
            Button(action: { 
                withAnimation {
                    isPresented = false
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(12)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .overlay(alignment: .trailing) {
            // Context Menu (3 dots)
            Menu {
                // Add to playlist
                Button(action: { showingPlaylistPicker = true }) {
                    Label("Add to Playlist", systemImage: "plus")
                }
                
                Divider()
                
                Button(action: { playerViewModel.toggleQueue() }) {
                    Label(playerViewModel.showQueue ? "Hide Queue" : "Show Queue", systemImage: "list.bullet")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
            }
            .buttonStyle(.plain)
            .padding(.trailing, Theme.Spacing.xl)
        }
        .sheet(isPresented: $showingPlaylistPicker) {
            if let track = playerViewModel.currentTrack {
                PlaylistPickerSheet(tracks: [track])
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(.white.opacity(0.2))
                    
                    // Progress fill
                    Capsule()
                        .fill(.white)
                        .frame(width: geometry.size.width * currentProgress)
                }
                .frame(height: 6)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDraggingProgress = true
                            dragProgress = max(0, min(1, value.location.x / geometry.size.width))
                        }
                        .onEnded { value in
                            let progress = max(0, min(1, value.location.x / geometry.size.width))
                            playerViewModel.seek(toProgress: progress)
                            isDraggingProgress = false
                        }
                )
            }
            .frame(height: 6)
            .padding(.horizontal, 100) // Much wider margins for cleaner look
            
            // Time labels
            HStack {
                Text(playerProgress.formattedCurrentTime)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text(playerProgress.formattedDuration)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 100)
        }
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        HStack(spacing: 40) {
            // Shuffle
            Button(action: { playerViewModel.toggleShuffle() }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 22))
                    .foregroundColor(playerViewModel.isShuffleEnabled ? Theme.accentPrimary : .white.opacity(0.4))
            }
            .buttonStyle(.plain)
            
            // Previous
            Button(action: { playerViewModel.previous() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            
            // Play/Pause
            Button(action: { playerViewModel.togglePlayPause() }) {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.black)
                        .offset(x: playerViewModel.isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(1.0) // Placeholder for press animation if needed
            
            // Next
            Button(action: { playerViewModel.next() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            
            // Repeat
            Button(action: { playerViewModel.cycleRepeatMode() }) {
                Image(systemName: playerViewModel.repeatMode.icon)
                    .font(.system(size: 22))
                    .foregroundColor(playerViewModel.repeatMode != .off ? Theme.accentPrimary : .white.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Helpers
    
    private func updateColors() {
        guard let track = playerViewModel.currentTrack else {
            dominantColors = .default
            return
        }
        
        // Extract colors in background
        DispatchQueue.global(qos: .userInitiated).async {
            let colors = ColorExtractor.extractColors(from: track.artwork)
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.5)) {
                    dominantColors = colors
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        
        var body: some View {
            FullScreenPlayerView(
                playerViewModel: PlayerViewModel(),
                isPresented: $isPresented
            )
            .frame(width: 1200, height: 800)
        }
    }
    
    return PreviewWrapper()
}
