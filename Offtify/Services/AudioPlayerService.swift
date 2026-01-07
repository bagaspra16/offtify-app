//
//  AudioPlayerService.swift
//  Offtify
//
//  Audio playback engine using AVFoundation
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

/// Audio playback service using AVQueuePlayer
final class AudioPlayerService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AudioPlayerService()
    
    // MARK: - Published Properties
    
    @Published private(set) var playbackState: PlaybackState = .idle
    @Published private(set) var currentTrack: Track?
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var volume: Float = 0.8 {
        didSet {
            player?.volume = volume
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
    
    private var player: AVQueuePlayer?
    private var playerItems: [AVPlayerItem] = []
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupAudioSession()
    }
    
    deinit {
        removeTimeObserver()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        // macOS doesn't require explicit audio session configuration like iOS
        // but we can set up notification observers
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] notification in
                self?.handleTrackEnd(notification)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Playback Control
    
    /// Play a single track
    func play(_ track: Track) {
        queue = [track]
        currentIndex = 0
        playTrackAtCurrentIndex()
    }
    
    /// Play a track from a queue
    func play(_ track: Track, in tracks: [Track]) {
        queue = isShuffleEnabled ? tracks.shuffled() : tracks
        
        if let index = queue.firstIndex(of: track) {
            currentIndex = index
        } else {
            currentIndex = 0
        }
        
        playTrackAtCurrentIndex()
    }
    
    /// Play all tracks starting from the first
    func playAll(_ tracks: [Track]) {
        guard !tracks.isEmpty else { return }
        queue = isShuffleEnabled ? tracks.shuffled() : tracks
        currentIndex = 0
        playTrackAtCurrentIndex()
    }
    
    /// Resume or start playback
    func play() {
        guard let player = player else {
            if let track = currentTrack {
                play(track)
            }
            return
        }
        
        player.play()
        playbackState = .playing
    }
    
    /// Pause playback
    func pause() {
        player?.pause()
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
        player?.pause()
        player?.removeAllItems()
        player = nil
        playbackState = .idle
        currentTime = 0
    }
    
    /// Seek to a specific time
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 1000)
        player?.seek(to: cmTime) { [weak self] completed in
            if completed {
                self?.currentTime = time
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
        
        // Add current to history
        if let current = currentTrack {
            playbackHistory.append(current)
        }
        
        switch repeatMode {
        case .one:
            // Replay the same track
            playTrackAtCurrentIndex()
        case .all:
            currentIndex = (currentIndex + 1) % queue.count
            playTrackAtCurrentIndex()
        case .off:
            if currentIndex < queue.count - 1 {
                currentIndex += 1
                playTrackAtCurrentIndex()
            } else {
                stop()
            }
        }
    }
    
    /// Play previous track
    func previous() {
        // If more than 3 seconds in, restart current track
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        
        // Try to get from history
        if let lastTrack = playbackHistory.popLast() {
            if let index = queue.firstIndex(of: lastTrack) {
                currentIndex = index
                playTrackAtCurrentIndex()
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
        
        playTrackAtCurrentIndex()
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
    }
    
    /// Cycle through repeat modes
    func cycleRepeatMode() {
        let allCases = RepeatMode.allCases
        if let currentModeIndex = allCases.firstIndex(of: repeatMode) {
            let nextIndex = (currentModeIndex + 1) % allCases.count
            repeatMode = allCases[nextIndex]
        }
    }
    
    /// Add track to the end of the queue
    func addToQueue(_ track: Track) {
        queue.append(track)
    }
    
    /// Add track to play next
    func playNext(_ track: Track) {
        if queue.isEmpty {
            queue.append(track)
        } else {
            queue.insert(track, at: currentIndex + 1)
        }
    }
    
    /// Remove track from queue
    func removeFromQueue(at index: Int) {
        guard queue.indices.contains(index) else { return }
        queue.remove(at: index)
        
        if index < currentIndex {
            currentIndex -= 1
        } else if index == currentIndex {
            // If removing current track, play next
            if !queue.isEmpty {
                currentIndex = min(currentIndex, queue.count - 1)
                playTrackAtCurrentIndex()
            } else {
                stop()
            }
        }
    }
    
    /// Clear the queue
    func clearQueue() {
        stop()
        queue.removeAll()
        currentIndex = 0
    }
    
    // MARK: - Private Methods
    
    private func playTrackAtCurrentIndex() {
        guard queue.indices.contains(currentIndex) else {
            stop()
            return
        }
        
        let track = queue[currentIndex]
        currentTrack = track
        playbackState = .loading
        
        // Remove existing observers and player
        removeTimeObserver()
        player?.removeAllItems()
        
        // Create player item
        let playerItem = AVPlayerItem(url: track.fileURL)
        
        // Create or reuse player
        if player == nil {
            player = AVQueuePlayer(playerItem: playerItem)
            player?.volume = volume
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        // Update duration when ready
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .readyToPlay {
                    self?.duration = CMTimeGetSeconds(playerItem.duration)
                    if self?.duration.isNaN == true || self?.duration.isInfinite == true {
                        self?.duration = track.duration
                    }
                }
            }
            .store(in: &cancellables)
        
        // Start playback
        player?.play()
        playbackState = .playing
        
        // Add time observer
        addTimeObserver()
    }
    
    private func addTimeObserver() {
        guard timeObserver == nil else { return }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: 1000)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func handleTrackEnd(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.next()
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
