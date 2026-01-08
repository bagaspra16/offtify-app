//
//  AudioConfig.swift
//  Offtify
//
//  Configuration for audio playback settings
//

import Foundation

struct AudioConfig: Codable, Equatable {
    /// Whether crossfade is enabled between tracks
    var isCrossfadeEnabled: Bool = true
    
    /// Duration of the crossfade in seconds
    var crossfadeDuration: TimeInterval = 4.0
    
    /// Default configuration
    static let `default` = AudioConfig()
}
