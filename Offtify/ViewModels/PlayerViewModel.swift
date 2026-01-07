//
//  PlayerViewModel.swift
//  Offtify
//
//  ViewModel for managing audio playback state
//

import Foundation
import Combine

/// Separate object for high-frequency progress updates
/// This ensures only views that actually need the progress bar will redraw,
/// preventing the entire app from lagging during playback.
@MainActor
final class PlayerProgress: ObservableObject {
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var formattedCurrentTime: String {
        formatTime(currentTime)
    }
    
    var formattedDuration: String {
        formatTime(duration)
    }
    
    var formattedRemainingTime: String {
        "-" + formatTime(max(duration - currentTime, 0))
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        guard !time.isNaN && !time.isInfinite else { return "0:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// View model for the audio player (Low frequency updates only)
@MainActor
final class PlayerViewModel: ObservableObject {
    
    // MARK: - Published Properties (Low Frequency)
    
    @Published var currentTrack: Track?
    @Published var isPlaying: Bool = false
    @Published var volume: Float = 0.8
    @Published var isShuffleEnabled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var queue: [Track] = []
    @Published var showQueue: Bool = false
    
    // MARK: - Independent Progress Object (High Frequency)
    // Views that need a progress bar should observe this object directly
    let progress: PlayerProgress = PlayerProgress()
    
    // MARK: - Computed Properties
    
    var hasCurrentTrack: Bool {
        currentTrack != nil
    }
    
    // MARK: - Services
    
    private let audioService = AudioPlayerService.shared
    private var cancellables = Set<AnyCancellable>()
    private weak var libraryViewModel: LibraryViewModel?
    
    // MARK: - Initialization
    
    init(libraryViewModel: LibraryViewModel? = nil) {
        self.libraryViewModel = libraryViewModel
        setupBindings()
    }
    
    func setLibraryViewModel(_ viewModel: LibraryViewModel) {
        self.libraryViewModel = viewModel
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Observe playback state
        audioService.$playbackState
            .receive(on: DispatchQueue.main)
            .map { $0 == .playing }
            .assign(to: &$isPlaying)
        
        // Observe current track
        audioService.$currentTrack
            .receive(on: DispatchQueue.main)
            .sink { [weak self] track in
                self?.currentTrack = track
                if let track = track {
                    self?.libraryViewModel?.addToRecentlyPlayed(track)
                }
            }
            .store(in: &cancellables)
        
        // Observe current time -> SEND TO SEPARATE PROGRESS OBJECT
        // This prevents PlayerViewModel from publishing, thus preventing App-wide redraws
        audioService.$currentTime
            .receive(on: DispatchQueue.main)
            .assign(to: &progress.$currentTime)
        
        // Observe duration -> SEND TO SEPARATE PROGRESS OBJECT
        audioService.$duration
            .receive(on: DispatchQueue.main)
            .assign(to: &progress.$duration)
        
        // Observe volume
        audioService.$volume
            .receive(on: DispatchQueue.main)
            .assign(to: &$volume)
        
        // Observe shuffle
        audioService.$isShuffleEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: &$isShuffleEnabled)
        
        // Observe repeat mode
        audioService.$repeatMode
            .receive(on: DispatchQueue.main)
            .assign(to: &$repeatMode)
        
        // Observe queue
        audioService.$queue
            .receive(on: DispatchQueue.main)
            .assign(to: &$queue)
    }
    
    // MARK: - Playback Actions
    
    /// Play a track
    func play(_ track: Track) {
        audioService.play(track)
    }
    
    /// Play a track from a list
    func play(_ track: Track, in tracks: [Track]) {
        audioService.play(track, in: tracks)
    }
    
    /// Play all tracks
    func playAll(_ tracks: [Track]) {
        audioService.playAll(tracks)
    }
    
    /// Resume playback
    func play() {
        audioService.play()
    }
    
    /// Pause playback
    func pause() {
        audioService.pause()
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        audioService.togglePlayPause()
    }
    
    /// Stop playback
    func stop() {
        audioService.stop()
    }
    
    /// Play next track
    func next() {
        audioService.next()
    }
    
    /// Play previous track
    func previous() {
        audioService.previous()
    }
    
    /// Seek to time
    func seek(to time: TimeInterval) {
        audioService.seek(to: time)
    }
    
    /// Seek to progress (0-1)
    func seek(toProgress progressVal: Double) {
        audioService.seek(toProgress: progressVal)
    }
    
    /// Set volume
    func setVolume(_ volume: Float) {
        audioService.volume = volume
        self.volume = volume
    }
    
    /// Toggle shuffle
    func toggleShuffle() {
        audioService.toggleShuffle()
    }
    
    /// Cycle repeat mode
    func cycleRepeatMode() {
        audioService.cycleRepeatMode()
    }
    
    /// Add to queue
    func addToQueue(_ track: Track) {
        audioService.addToQueue(track)
    }
    
    /// Play next in queue
    func playNext(_ track: Track) {
        audioService.playNext(track)
    }
    
    /// Remove from queue
    func removeFromQueue(at index: Int) {
        audioService.removeFromQueue(at: index)
    }
    
    /// Clear queue
    func clearQueue() {
        audioService.clearQueue()
    }
    
    /// Toggle queue visibility
    func toggleQueue() {
        showQueue.toggle()
    }
}
