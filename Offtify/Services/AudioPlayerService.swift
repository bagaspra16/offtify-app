//
//  AudioPlayerService.swift
//  Offtify
//
//  Audio playback engine using Dual AVPlayer (Double Buffering)
//  Supports Gapless Playback and Crossfading
//

import Foundation
import AVFoundation
import Combine

/// Playback state enumeration
enum PlaybackState: Equatable {
    case idle
    case playing
    case paused
    case loading
}

/// Repeat mode enumeration
enum RepeatMode: Int, CaseIterable {
    case off = 0
    case all
    case one
    
    var icon: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
}

/// Audio playback service using Dual AVPlayer architecture
final class AudioPlayerService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AudioPlayerService()
    
    // MARK: - Published Properties
    
    @Published private(set) var playbackState: PlaybackState = .idle
    @Published private(set) var currentTrack: Track?
    
    // Incoming track for crossfade visualization
    @Published private(set) var incomingTrack: Track?
    // 0.0 to 1.0 representing crossfade completion
    @Published private(set) var crossfadeProgress: Double = 0
    
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    
    @Published var volume: Float = 0.8 {
        didSet {
            // Apply volume to active players, respecting crossfade
            updatePlayerVolumes()
        }
    }
    
    @Published var config: AudioConfig {
        didSet {
            saveConfig()
        }
    }
    
    @Published var isShuffleEnabled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    
    // MARK: - Queue Properties
    
    @Published private(set) var queue: [Track] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var playbackHistory: [Track] = []
    
    // MARK: - Progress Properties
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var remainingTime: TimeInterval {
        max(duration - currentTime, 0)
    }
    
    // MARK: - Private Properties
    
    // Dual Player Architecture
    private var primaryPlayer: AVPlayer?
    private var secondaryPlayer: AVPlayer?
    
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    private var isCrossfading: Bool = false
    private var crossfadeStartTime: TimeInterval = 0
    
    // Constants
    private let configKey = "offtify_audio_config"
    
    // MARK: - Initialization
    
    private init() {
        // Load config
        if let data = UserDefaults.standard.data(forKey: configKey),
           let savedConfig = try? JSONDecoder().decode(AudioConfig.self, from: data) {
            self.config = savedConfig
        } else {
            self.config = .default
        }
        
        setupAudioSession()
    }
    
    deinit {
        removeTimeObserver()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        // macOS doesn't require explicit audio session configuration like iOS
        // but we can set up notification observers
    }
    
    private func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
    }
    
    // MARK: - Playback Control
    
    /// Play a single track
    func play(_ track: Track) {
        queue = [track]
        currentIndex = 0
        playTrackAtCurrentIndex(forceRestart: true)
    }
    
    /// Play a track from a queue
    func play(_ track: Track, in tracks: [Track]) {
        queue = isShuffleEnabled ? tracks.shuffled() : tracks
        
        if let index = queue.firstIndex(of: track) {
            currentIndex = index
        } else {
            currentIndex = 0
        }
        
        playTrackAtCurrentIndex(forceRestart: true)
    }
    
    /// Play all tracks starting from the first
    func playAll(_ tracks: [Track]) {
        guard !tracks.isEmpty else { return }
        queue = isShuffleEnabled ? tracks.shuffled() : tracks
        currentIndex = 0
        playTrackAtCurrentIndex(forceRestart: true)
    }
    
    /// Resume or start playback
    func play() {
        guard let player = primaryPlayer else {
            if let track = currentTrack {
                play(track)
            }
            return
        }
        
        player.play()
        if isCrossfading {
            secondaryPlayer?.play()
        }
        playbackState = .playing
    }
    
    /// Pause playback
    func pause() {
        primaryPlayer?.pause()
        secondaryPlayer?.pause()
        playbackState = .paused
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        switch playbackState {
        case .playing:
            pause()
        case .paused, .idle:
            play()
        case .loading:
            break
        }
    }
    
    /// Stop playback completely
    func stop() {
        removeTimeObserver()
        primaryPlayer?.pause()
        secondaryPlayer?.pause()
        primaryPlayer = nil
        secondaryPlayer = nil
        incomingTrack = nil
        isCrossfading = false
        playbackState = .idle
        currentTime = 0
    }
    
    /// Seek to a specific time
    func seek(to time: TimeInterval) {
        // If we are crossfading and seek, we should probably cancel the crossfade
        // and just play the primary track or jump to the next one depending on where we seek
        // For simplicity: seeking cancels crossfade and hard-cuts to primary track logic
        
        if isCrossfading {
            cancelCrossfade()
        }
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        primaryPlayer?.seek(to: cmTime) { [weak self] completed in
            if completed {
                self?.currentTime = time
                // Check if we need to prepare next track again
                self?.prepareNextTrack()
            }
        }
    }
    
    /// Seek to a specific progress (0-1)
    func seek(toProgress progress: Double) {
        let time = duration * max(0, min(1, progress))
        seek(to: time)
    }
    
    /// Skip forward by seconds
    func skipForward(by seconds: TimeInterval = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    /// Skip backward by seconds
    func skipBackward(by seconds: TimeInterval = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    /// Play next track
    func next() {
        guard !queue.isEmpty else { return }
        
        // If crossfading, "Next" basically means "Finish Crossfade Immediately"
        if isCrossfading {
            completeCrossfade()
            return
        }
        
        // Add current to history
        if let current = currentTrack {
            playbackHistory.append(current)
        }
        
        advanceQueueIndex()
        playTrackAtCurrentIndex(forceRestart: true)
    }
    
    /// Play previous track
    func previous() {
        // If more than 3 seconds in, restart current track
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        
        if isCrossfading {
            cancelCrossfade()
        }
        
        // Try to get from history
        if let lastTrack = playbackHistory.popLast() {
            if let index = queue.firstIndex(of: lastTrack) {
                currentIndex = index
                playTrackAtCurrentIndex(forceRestart: true)
            }
            return
        }
        
        // Go to previous in queue
        guard !queue.isEmpty else { return }
        
        if currentIndex > 0 {
            currentIndex -= 1
        } else if repeatMode == .all {
            currentIndex = queue.count - 1
        }
        
        playTrackAtCurrentIndex(forceRestart: true)
    }
    
    /// Toggle shuffle mode
    func toggleShuffle() {
        isShuffleEnabled.toggle()
        
        if isShuffleEnabled && !queue.isEmpty {
            let current = currentTrack
            queue.shuffle()
            if let current = current, let newIndex = queue.firstIndex(of: current) {
                currentIndex = newIndex
            }
        }
        
        // Queue order changed, so next track might be different
        prepareNextTrack()
    }
    
    /// Cycle through repeat modes
    func cycleRepeatMode() {
        let allCases = RepeatMode.allCases
        if let currentModeIndex = allCases.firstIndex(of: repeatMode) {
            let nextIndex = (currentModeIndex + 1) % allCases.count
            repeatMode = allCases[nextIndex]
        }
        
        // Repeat mode changed, so next track might be different
        prepareNextTrack()
    }
    
    /// Add track to the end of the queue
    func addToQueue(_ track: Track) {
        queue.append(track)
        if queue.count == 1 { // Was empty
             currentIndex = 0
             playTrackAtCurrentIndex(forceRestart: true)
        } else {
            // Check if this affects next track
             prepareNextTrack()
        }
    }
    
    /// Add track to play next
    func playNext(_ track: Track) {
        if queue.isEmpty {
            queue.append(track)
            currentIndex = 0
            playTrackAtCurrentIndex(forceRestart: true)
        } else {
            queue.insert(track, at: currentIndex + 1)
            prepareNextTrack()
        }
    }
    
    /// Remove track from queue
    func removeFromQueue(at index: Int) {
        guard queue.indices.contains(index) else { return }
        queue.remove(at: index)
        
        if index < currentIndex {
            currentIndex -= 1
        } else if index == currentIndex {
            // removing current playing track
             if !queue.isEmpty {
                 currentIndex = min(currentIndex, queue.count - 1)
                 playTrackAtCurrentIndex(forceRestart: true)
             } else {
                 stop()
             }
        } else {
             // Removed something after current, might be next track
             prepareNextTrack()
        }
    }
    
    /// Clear the queue
    func clearQueue() {
        stop()
        queue.removeAll()
        currentIndex = 0
    }
    
    // MARK: - Dual Player Logic
    
    private func playTrackAtCurrentIndex(forceRestart: Bool = false) {
        guard queue.indices.contains(currentIndex) else {
            stop()
            return
        }
        
        let track = queue[currentIndex]
        
        // If we are just moving comfortably to the next track that is already preloaded (secondary)
        // and we are NOT forcing a restart (like user clicking a song),
        // we should have handled this in crossfading logic.
        // This method is primarily for "Hard" changes (Play specific song, Prev, Next button)
        
        cancelCrossfade()
        
        currentTrack = track
        incomingTrack = nil
        playbackState = .loading
        
        // Cleanup
        removeTimeObserver()
        primaryPlayer?.pause()
        primaryPlayer = nil
        secondaryPlayer?.pause()
        secondaryPlayer = nil
        
        // Init Primary Player
        let playerItem = AVPlayerItem(url: track.fileURL)
        primaryPlayer = AVPlayer(playerItem: playerItem)
        primaryPlayer?.volume = volume
        
        // Observe status
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .readyToPlay {
                    self?.handlePrimaryReadyToPlay(item: playerItem, track: track)
                }
            }
            .store(in: &cancellables)
            
        // Observe End
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .sink { [weak self] _ in
                self?.handleTrackEnd()
            }
            .store(in: &cancellables)
        
        primaryPlayer?.play()
        playbackState = .playing
        addTimeObserver()
        
        // Preload next
        prepareNextTrack()
    }
    
    private func handlePrimaryReadyToPlay(item: AVPlayerItem, track: Track) {
        let durationSeconds = CMTimeGetSeconds(item.duration)
        if !durationSeconds.isNaN && !durationSeconds.isInfinite {
            self.duration = durationSeconds
        } else {
            self.duration = track.duration
        }
    }
    
    private func prepareNextTrack() {
        // Identify next track index
        var nextIndex = -1
        
        switch repeatMode {
        case .one:
            nextIndex = currentIndex // Same track
        case .all:
            nextIndex = (currentIndex + 1) % queue.count
        case .off:
            if currentIndex < queue.count - 1 {
                nextIndex = currentIndex + 1
            }
        }
        
        guard nextIndex >= 0, queue.indices.contains(nextIndex) else {
            secondaryPlayer = nil
            incomingTrack = nil
            return
        }
        
        let nextTrack = queue[nextIndex]
        
        // Avoid reloading if already loaded
        if secondaryPlayer != nil && incomingTrack?.id == nextTrack.id {
             return
        }
        
        incomingTrack = nextTrack
        let item = AVPlayerItem(url: nextTrack.fileURL)
        secondaryPlayer = AVPlayer(playerItem: item)
        secondaryPlayer?.volume = 0 // Start silent
        secondaryPlayer?.automaticallyWaitsToMinimizeStalling = false
        
        // We don't play yet. We wait for crossfade time.
    }
    
    private func addTimeObserver() {
        guard timeObserver == nil else { return }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: 1000)
        timeObserver = primaryPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = CMTimeGetSeconds(time)
            self.checkCrossfade()
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            primaryPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    // MARK: - Crossfade Logic
    
    private func checkCrossfade() {
        guard config.isCrossfadeEnabled,
              let secondary = secondaryPlayer,
              let _ = incomingTrack,
              duration > 0 else { return }
        
        let remaining = duration - currentTime
        
        if !isCrossfading {
            // Start Crossfade?
            if remaining <= config.crossfadeDuration {
                startCrossfade()
            }
        } else {
            // Update Crossfade
            updateCrossfade(remaining: remaining)
        }
    }
    
    private func startCrossfade() {
        guard !isCrossfading else { return }
        isCrossfading = true
        secondaryPlayer?.seek(to: .zero)
        secondaryPlayer?.play()
        print("Starting crossfade...")
    }
    
    private func updateCrossfade(remaining: TimeInterval) {
        let duration = config.crossfadeDuration
        guard duration > 0 else { return }
        
        // 0.0 (start) -> 1.0 (finish)
        // remaining goes from duration -> 0
        
        let progress = 1.0 - (max(0, remaining) / duration)
        self.crossfadeProgress = progress
        
        updatePlayerVolumes()
        
        if remaining <= 0 {
            completeCrossfade()
        }
    }
    
    private func updatePlayerVolumes() {
        guard isCrossfading else {
            primaryPlayer?.volume = volume
            return
        }
        
        // Equal power crossfade curve
        // Or simple linear for now
        let fadeOut = Float(1.0 - crossfadeProgress) * volume
        let fadeIn = Float(crossfadeProgress) * volume
        
        primaryPlayer?.volume = fadeOut
        secondaryPlayer?.volume = fadeIn
    }
    
    private func cancelCrossfade() {
        isCrossfading = false
        crossfadeProgress = 0
        secondaryPlayer?.pause()
        secondaryPlayer = nil
        incomingTrack = nil // We'll re-determine who is next
        primaryPlayer?.volume = volume
    }
    
    /// Swap secondary to primary
    private func completeCrossfade() {
        print("Completing crossfade...")
        
        // 1. Advance queue index logic
        advanceQueueIndex()
        
        // 2. Secondary becomes Primary
        // Stop old primary
        removeTimeObserver()
        primaryPlayer?.pause()
        
        // Create new primary from secondary
        currentTrack = incomingTrack
        primaryPlayer = secondaryPlayer
        primaryPlayer?.volume = volume // Ensure full volume
        
        // Reset secondary
        secondaryPlayer = nil
        incomingTrack = nil
        isCrossfading = false
        crossfadeProgress = 0
        
        // 3. Setup new primary
        addTimeObserver()
        
        // Observe End for new primary
        if let currentItem = primaryPlayer?.currentItem {
             NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: currentItem)
                .sink { [weak self] _ in
                    self?.handleTrackEnd()
                }
                .store(in: &cancellables)
        }
        
        // 4. Preload next
        // We don't call playTrackAtCurrentIndex because that would reset the primary player
        // which we just successfully swapped.
        
        // Just prepare next track
        prepareNextTrack()
    }
    
    private func advanceQueueIndex() {
        switch repeatMode {
        case .one:
            // Queue index stays same
            break
        case .all:
            currentIndex = (currentIndex + 1) % queue.count
        case .off:
            if currentIndex < queue.count - 1 {
                currentIndex += 1
            } else {
                // End of queue
                stop()
            }
        }
    }
    
    private func handleTrackEnd() {
        if isCrossfading {
            // If we reached the end and crossfade logic didn't trigger complete (maybe short track), force it
             completeCrossfade()
        } else {
            // Gapless transition (Crossfade disabled or track too short)
            next() 
        }
    }
}

// MARK: - Formatted Time Helpers

extension AudioPlayerService {
    var formattedCurrentTime: String {
        formatTime(currentTime)
    }
    
    var formattedDuration: String {
        formatTime(duration)
    }
    
    var formattedRemainingTime: String {
        "-" + formatTime(remainingTime)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard !time.isNaN && !time.isInfinite else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AudioConfig

struct AudioConfig: Codable, Equatable {
    /// Whether crossfade is enabled between tracks
    var isCrossfadeEnabled: Bool = true
    
    /// Duration of the crossfade in seconds
    var crossfadeDuration: TimeInterval = 4.0
    
    /// Default configuration
    static let `default` = AudioConfig()
}
