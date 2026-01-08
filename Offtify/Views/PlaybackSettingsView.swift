//
//  PlaybackSettingsView.swift
//  Offtify
//
//  Settings for playback features like Crossfade
//

import SwiftUI

struct PlaybackSettingsView: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Playback Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(hex: "1A1F2E"))
            
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    
                    // Crossfade Section
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundColor(Theme.accentPrimary)
                            Text("Crossfade")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { playerViewModel.config.isCrossfadeEnabled },
                                set: { newValue in
                                    playerViewModel.updateConfig(
                                        isCrossfadeEnabled: newValue,
                                        crossfadeDuration: playerViewModel.config.crossfadeDuration
                                    )
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: Theme.accentPrimary))
                        }
                        
                        if playerViewModel.config.isCrossfadeEnabled {
                            VStack(spacing: Theme.Spacing.sm) {
                                HStack {
                                    Text("Duration")
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                    Text("\(Int(playerViewModel.config.crossfadeDuration))s")
                                        .bold()
                                        .foregroundColor(Theme.accentPrimary)
                                        .monospacedDigit()
                                }
                                
                                Slider(
                                    value: Binding(
                                        get: { playerViewModel.config.crossfadeDuration },
                                        set: { newValue in
                                            playerViewModel.updateConfig(
                                                isCrossfadeEnabled: playerViewModel.config.isCrossfadeEnabled,
                                                crossfadeDuration: newValue
                                            )
                                        }
                                    ),
                                    in: 1...12,
                                    step: 1
                                )
                                .accentColor(Theme.accentPrimary)
                                
                                HStack {
                                    Text("1s")
                                    Spacer()
                                    Text("12s")
                                }
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.4))
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding()
                    .background(Color(hex: "1A1F2E"))
                    .cornerRadius(16)
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Label("About Crossfade", systemImage: "info.circle")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            
                        Text("Crossfade overlaps the end of the current song with the beginning of the next one for a seamless transition. Tracks with gapless metadata will always play without gaps regardless of this setting.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .background(Color(hex: "0B0F1A"))
        .frame(width: 400, height: 500)
    }
}
