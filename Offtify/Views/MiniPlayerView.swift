//
//  MiniPlayerView.swift
//  Offtify
//
//  Floating mini player at the bottom of the window
//

import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @ObservedObject var playerProgress: PlayerProgress
    var onArtworkTap: (() -> Void)? = nil
    
    @State private var isDraggingProgress: Bool = false
    @State private var dragProgress: Double = 0
    @State private var isHoveringProgress: Bool = false
    @State private var volumeSliderVisible: Bool = false
    
    init(playerViewModel: PlayerViewModel, onArtworkTap: (() -> Void)? = nil) {
        self.playerViewModel = playerViewModel
        self.playerProgress = playerViewModel.progress
        self.onArtworkTap = onArtworkTap
    }
    
    private var currentProgress: Double {
        isDraggingProgress ? dragProgress : playerProgress.progress
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Bar
            progressBar
            
            // Player Content
            HStack(spacing: Theme.Spacing.lg) {
                // Track Info
                trackInfo
                
                Spacer()
                
                // Playback Controls
                playbackControls
                
                Spacer()
                
                // Secondary Controls
                secondaryControls
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(
            ZStack {
                // Glassmorphism background
                Color.white.opacity(BackgroundManager.shared.uiOpacity)
                
                // Blur effect
                .background(.ultraThinMaterial)
            }
            .padding(.top, -10)
        )
        .glassmorphism(cornerRadius: 0)
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Theme.surface)
                
                // Progress fill
                Rectangle()
                    .fill(Theme.gradientProgress)
                    .frame(width: geometry.size.width * currentProgress)
                
                // Hover indicator
                if isHoveringProgress {
                    Circle()
                        .fill(Theme.accentPrimary)
                        .frame(width: 12, height: 12)
                        .position(
                            x: geometry.size.width * currentProgress,
                            y: geometry.size.height / 2
                        )
                        .shadow(color: Theme.accentPrimary.opacity(0.5), radius: 4)
                }
            }
            .frame(height: isHoveringProgress ? 6 : 3)
            .animation(Theme.Animation.quick, value: isHoveringProgress)
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
            .onHover { hovering in
                withAnimation(Theme.Animation.quick) {
                    isHoveringProgress = hovering
                }
            }
        }
        .frame(height: isHoveringProgress ? 6 : 3)
    }
    
    // MARK: - Track Info
    
    private var trackInfo: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Artwork
            if let track = playerViewModel.currentTrack {
                ArtworkView(artwork: track.artwork, size: 56, cornerRadius: 10)
                    .shadow(color: Theme.Shadow.soft, radius: 8, x: 0, y: 4)
            } else {
                ArtworkView(artwork: nil, size: 56, cornerRadius: 10)
            }
            
            // Track Details
            VStack(alignment: .leading, spacing: 3) {
                if let track = playerViewModel.currentTrack {
                    Text(track.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(1)
                } else {
                    Text("Not Playing")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .frame(width: 180, alignment: .leading)
        }
        .onTapGesture {
            onArtworkTap?()
        }
    }
    
    // MARK: - Playback Controls
    
    private var playbackControls: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Shuffle Button
            Button(action: {
                playerViewModel.toggleShuffle()
            }) {
                Image(systemName: "shuffle")
                    .font(.system(size: 14))
                    .foregroundColor(playerViewModel.isShuffleEnabled ? Theme.accentPrimary : Theme.textSecondary)
            }
            .buttonStyle(IconButtonStyle(size: 32, showBackground: false))
            
            // Previous Button
            Button(action: {
                playerViewModel.previous()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.textPrimary)
            }
            .buttonStyle(IconButtonStyle(size: 40, showBackground: false))
            
            // Play/Pause Button
            Button(action: {
                playerViewModel.togglePlayPause()
            }) {
                Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            .buttonStyle(PlayButtonStyle(isPlaying: playerViewModel.isPlaying))
            .disabled(!playerViewModel.hasCurrentTrack)
            
            // Next Button
            Button(action: {
                playerViewModel.next()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.textPrimary)
            }
            .buttonStyle(IconButtonStyle(size: 40, showBackground: false))
            
            // Repeat Button
            Button(action: {
                playerViewModel.cycleRepeatMode()
            }) {
                Image(systemName: playerViewModel.repeatMode.icon)
                    .font(.system(size: 14))
                    .foregroundColor(playerViewModel.repeatMode != .off ? Theme.accentPrimary : Theme.textSecondary)
            }
            .buttonStyle(IconButtonStyle(size: 32, showBackground: false))
        }
    }
    
    // MARK: - Secondary Controls
    
    private var secondaryControls: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Time Display
            HStack(spacing: Theme.Spacing.xs) {
                Text(playerProgress.formattedCurrentTime)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
                
                Text("/")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)
                
                Text(playerProgress.formattedDuration)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
            }
            .frame(width: 80)
            
            // Volume Control
            HStack(spacing: Theme.Spacing.xs) {
                Button(action: {
                    if playerViewModel.volume > 0 {
                        playerViewModel.setVolume(0)
                    } else {
                        playerViewModel.setVolume(0.8)
                    }
                }) {
                    Image(systemName: volumeIcon)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                
                Slider(value: Binding(
                    get: { Double(playerViewModel.volume) },
                    set: { playerViewModel.setVolume(Float($0)) }
                ), in: 0...1)
                .tint(Theme.accentPrimary)
                .frame(width: 80)
            }
            
            // Queue Button
            Button(action: {
                playerViewModel.toggleQueue()
            }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 12))
                    .foregroundColor(playerViewModel.showQueue ? Theme.accentPrimary : Theme.textSecondary)
            }
            .buttonStyle(IconButtonStyle(size: 28, showBackground: false))
        }
    }
    
    // MARK: - Helpers
    
    private var volumeIcon: String {
        let volume = playerViewModel.volume
        if volume == 0 {
            return "speaker.slash.fill"
        } else if volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
}

#Preview {
    VStack {
        Spacer()
        MiniPlayerView(playerViewModel: PlayerViewModel())
    }
    .frame(width: 900, height: 200)
    .background(Theme.backgroundPrimary)
}
