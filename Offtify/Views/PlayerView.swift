//
//  PlayerView.swift
//  Offtify
//
//  Full-screen now playing view with expanded controls
//

import SwiftUI

struct PlayerView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @ObservedObject var playerProgress: PlayerProgress
    @Environment(\.dismiss) private var dismiss
    
    @State private var isDraggingProgress: Bool = false
    @State private var dragProgress: Double = 0
    
    init(playerViewModel: PlayerViewModel) {
        self.playerViewModel = playerViewModel
        self.playerProgress = playerViewModel.progress
    }
    
    private var currentProgress: Double {
        isDraggingProgress ? dragProgress : playerProgress.progress
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with artwork blur
                backgroundView
                
                // Content
                VStack(spacing: Theme.Spacing.xxl) {
                    // Close Button
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(Theme.surface)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text("Now Playing")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                        
                        Spacer()
                        
                        // Placeholder for balance
                        Color.clear.frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    
                    Spacer()
                    
                    // Artwork
                    artworkSection
                    
                    // Track Info
                    trackInfoSection
                    
                    // Progress Bar
                    progressSection
                    
                    // Controls
                    controlsSection
                    
                    Spacer()
                    
                    // Queue Preview
                    if !playerViewModel.queue.isEmpty {
                        queuePreviewSection
                    }
                }
                .padding(.vertical, Theme.Spacing.xl)
            }
        }
        .background(Theme.backgroundPrimary)
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        Group {
            if let track = playerViewModel.currentTrack, let artwork = track.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 100)
                    .scaleEffect(1.5)
                    .opacity(0.3)
            } else {
                Theme.gradientAccent
                    .opacity(0.2)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Artwork Section
    
    private var artworkSection: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width - 80, geometry.size.height)
            let artworkSize = min(size, 400) // Max size constraint
            
            ZStack {
                if let track = playerViewModel.currentTrack {
                    ArtworkView(artwork: track.artwork, size: artworkSize, cornerRadius: 20)
                } else {
                    ArtworkView(artwork: nil, size: artworkSize, cornerRadius: 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: Theme.Shadow.soft, radius: 40, x: 0, y: 20)
        }
        .frame(height: 400) // Allocate space for the artwork container
        .layoutPriority(1)
    }
    
    // MARK: - Track Info Section
    
    private var trackInfoSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            if let track = playerViewModel.currentTrack {
                Text(track.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
                
                Text(track.album)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(1)
            } else {
                Text("Not Playing")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Theme.surface)
                    
                    // Progress fill
                    Capsule()
                        .fill(Theme.gradientProgress)
                        .frame(width: geometry.size.width * currentProgress)
                    
                    // Knob
                    Circle()
                        .fill(Theme.accentPrimary)
                        .frame(width: 14, height: 14)
                        .position(
                            x: geometry.size.width * currentProgress,
                            y: geometry.size.height / 2
                        )
                        .shadow(color: Theme.accentPrimary.opacity(0.5), radius: 4)
                }
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
            
            // Time labels
            HStack {
                Text(playerProgress.formattedCurrentTime)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
                
                Spacer()
                
                Text(playerProgress.formattedRemainingTime)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(.horizontal, Theme.Spacing.xxl)
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        HStack(spacing: Theme.Spacing.xl) {
            // Shuffle
            Button(action: { playerViewModel.toggleShuffle() }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 18))
                    .foregroundColor(playerViewModel.isShuffleEnabled ? Theme.accentPrimary : Theme.textSecondary)
            }
            .buttonStyle(IconButtonStyle(size: 44, showBackground: false))
            
            // Previous
            Button(action: { playerViewModel.previous() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.textPrimary)
            }
            .buttonStyle(IconButtonStyle(size: 56, showBackground: false))
            
            // Play/Pause
            Button(action: { playerViewModel.togglePlayPause() }) {
                Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            .frame(width: 72, height: 72)
            .background(Theme.gradientAccent)
            .clipShape(Circle())
            .shadow(color: Theme.accentPrimary.opacity(0.5), radius: 20)
            
            // Next
            Button(action: { playerViewModel.next() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.textPrimary)
            }
            .buttonStyle(IconButtonStyle(size: 56, showBackground: false))
            
            // Repeat
            Button(action: { playerViewModel.cycleRepeatMode() }) {
                Image(systemName: playerViewModel.repeatMode.icon)
                    .font(.system(size: 18))
                    .foregroundColor(playerViewModel.repeatMode != .off ? Theme.accentPrimary : Theme.textSecondary)
            }
            .buttonStyle(IconButtonStyle(size: 44, showBackground: false))
        }
    }
    
    // MARK: - Queue Preview Section
    
    private var queuePreviewSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Up Next")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                
                Spacer()
                
                Button(action: { playerViewModel.toggleQueue() }) {
                    Text("Show Queue")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.accentPrimary)
                }
                .buttonStyle(.plain)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(playerViewModel.queue.prefix(5)) { track in
                        VStack(spacing: Theme.Spacing.xs) {
                            ArtworkView(artwork: track.artwork, size: 60, cornerRadius: 8)
                            
                            Text(track.title)
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(1)
                            
                            Text(track.artist)
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textTertiary)
                                .lineLimit(1)
                        }
                        .frame(width: 70)
                    }
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .padding(.horizontal, Theme.Spacing.lg)
    }
}

#Preview {
    PlayerView(playerViewModel: PlayerViewModel())
        .frame(width: 500, height: 800)
}
