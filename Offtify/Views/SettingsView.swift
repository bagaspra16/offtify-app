//
//  SettingsView.swift
//  Offtify
//
//  Settings view for background customization
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var backgroundManager = BackgroundManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.xl)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    // Background Section
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Background")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text("Customize your app background with a personal image")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                        
                        // Background Preview
                        if backgroundManager.hasCustomBackground, let image = backgroundManager.customBackground {
                            ZStack {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                                            .stroke(Theme.textMuted.opacity(0.3), lineWidth: 1)
                                    )
                                
                                // Blur preview overlay
                                VStack {
                                    Spacer()
                                    
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Custom Background Active")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, Theme.Spacing.md)
                                    .padding(.vertical, Theme.Spacing.sm)
                                    .background(
                                        Capsule()
                                            .fill(.black.opacity(0.7))
                                    )
                                    .padding(Theme.Spacing.md)
                                }
                            }
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                                    .fill(Theme.gradientBackground)
                                    .frame(height: 200)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                                            .stroke(Theme.textMuted.opacity(0.3), lineWidth: 1)
                                    )
                                
                                VStack(spacing: Theme.Spacing.sm) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.textTertiary)
                                    
                                    Text("No custom background")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                        }
                        
                        // Action Buttons
                        HStack(spacing: Theme.Spacing.md) {
                            Button(action: {
                                backgroundManager.selectBackground()
                            }) {
                                HStack(spacing: Theme.Spacing.xs) {
                                    Image(systemName: "photo.badge.plus")
                                    Text(backgroundManager.hasCustomBackground ? "Change Background" : "Upload Background")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.primary)
                            
                            if backgroundManager.hasCustomBackground {
                                Button(action: {
                                    backgroundManager.removeBackground()
                                }) {
                                    HStack(spacing: Theme.Spacing.xs) {
                                        Image(systemName: "trash")
                                        Text("Remove")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                }
                                .buttonStyle(.secondary)
                            }
                        }
                    }
                    .padding(Theme.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .fill(Theme.surface)
                    )
                    
                    // Customization Section
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        HStack {
                            Text("Customization")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            
                            Spacer()
                            
                            Button("Reset Defaults") {
                                backgroundManager.resetDefaults()
                            }
                            .font(.system(size: 13))
                            .foregroundColor(Theme.accentPrimary)
                            .buttonStyle(.plain)
                        }
                        
                        Divider()
                        
                        // Sliders
                        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                            // Blur Radius
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                HStack {
                                    Text("Blur Radius")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text("\(Int(backgroundManager.blurRadius))px")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                
                                Slider(value: $backgroundManager.blurRadius, in: 0...300) {
                                    Text("Blur")
                                } onEditingChanged: { _ in
                                    backgroundManager.saveSettings()
                                }
                            }
                            
                            // UI Opacity
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                HStack {
                                    Text("Transparency") // Inverted for user understanding (High Transparency = Low Opacity)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text("\(Int((1.0 - backgroundManager.uiOpacity) * 100))%")
                                        .font(.system(size: 12))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                
                                // Slider tracks opacity (inverse of transparency)
                                Slider(value: Binding(
                                    get: { 1.0 - backgroundManager.uiOpacity },
                                    set: { backgroundManager.uiOpacity = 1.0 - $0 }
                                ), in: 0.0...1.0) {
                                    Text("Transparency")
                                } onEditingChanged: { _ in
                                    backgroundManager.saveSettings()
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Colors
                        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                            ColorPicker("Text Color", selection: Binding(
                                get: { backgroundManager.customTextColor },
                                set: {
                                    backgroundManager.customTextColor = $0
                                    backgroundManager.saveSettings()
                                }
                            ))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                            
                            ColorPicker("Accent Color", selection: Binding(
                                get: { backgroundManager.customAccentColor },
                                set: {
                                    backgroundManager.customAccentColor = $0
                                    backgroundManager.saveSettings()
                                }
                            ))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textPrimary)
                        }
                    }
                    .padding(Theme.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .fill(Theme.surface)
                    )
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "info.circle")
                                .foregroundColor(Theme.accentHighlight)
                            Text("Tips")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            InfoRow(icon: "photo.fill", text: "Use high-quality images for best results")
                            InfoRow(icon: "paintbrush.fill", text: "Background will be blurred for elegance")
                            InfoRow(icon: "eye.fill", text: "White theme ensures readability")
                        }
                    }
                    .padding(Theme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.md)
                            .fill(Theme.accentHighlight.opacity(0.1))
                    )
                }
                .padding(Theme.Spacing.xl)
            }
        }
        .frame(width: 600, height: 700)
        .background(
            ZStack {
                Color.white.opacity(BackgroundManager.shared.uiOpacity + 0.1)
                .background(.ultraThinMaterial)
            }
        )
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Theme.accentHighlight)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    SettingsView()
}
