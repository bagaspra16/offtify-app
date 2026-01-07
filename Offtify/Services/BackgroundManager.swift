//
//  BackgroundManager.swift
//  Offtify
//
//  Manages custom background images for the app
//

import SwiftUI
import AppKit

class BackgroundManager: ObservableObject {
    static let shared = BackgroundManager()
    
    @Published var customBackground: NSImage?
    @Published var hasCustomBackground: Bool = false
    
    // Customization Properties
    @Published var blurRadius: Double = 150
    @Published var uiOpacity: Double = 0.15
    @Published var customTextColor: Color = Color.white
    @Published var customAccentColor: Color = Color.white
    
    private let backgroundKey = "customBackgroundImageData"
    private let blurKey = "customBlurRadius"
    private let opacityKey = "customUiOpacity"
    private let textColorKey = "customTextColor"
    private let accentColorKey = "customAccentColor"
    
    init() {
        loadBackground()
        loadSettings()
    }
    
    // MARK: - Load Settings
    
    func loadSettings() {
        // Load Blur
        if UserDefaults.standard.object(forKey: blurKey) != nil {
            blurRadius = UserDefaults.standard.double(forKey: blurKey)
        }
        
        // Load Opacity
        if UserDefaults.standard.object(forKey: opacityKey) != nil {
            uiOpacity = UserDefaults.standard.double(forKey: opacityKey)
        }
        
        // Load Colors
        if let textData = UserDefaults.standard.string(forKey: textColorKey) {
            customTextColor = Color(hex: textData)
        }
        
        if let accentData = UserDefaults.standard.string(forKey: accentColorKey) {
            customAccentColor = Color(hex: accentData)
        }
    }
    
    // MARK: - Save Settings
    
    func saveSettings() {
        UserDefaults.standard.set(blurRadius, forKey: blurKey)
        UserDefaults.standard.set(uiOpacity, forKey: opacityKey)
        
        // Save colors as hex strings
        if let textHex = customTextColor.toHex() {
            UserDefaults.standard.set(textHex, forKey: textColorKey)
        }
        
        if let accentHex = customAccentColor.toHex() {
            UserDefaults.standard.set(accentHex, forKey: accentColorKey)
        }
    }
    
    // MARK: - Load Background
    
    func loadBackground() {
        guard let data = UserDefaults.standard.data(forKey: backgroundKey),
              let image = NSImage(data: data) else {
            hasCustomBackground = false
            customBackground = nil
            return
        }
        
        customBackground = image
        hasCustomBackground = true
    }
    
    // MARK: - Save Background
    
    func saveBackground(_ image: NSImage) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return
        }
        
        UserDefaults.standard.set(pngData, forKey: backgroundKey)
        customBackground = image
        hasCustomBackground = true
    }
    
    // MARK: - Remove Background
    
    func removeBackground() {
        UserDefaults.standard.removeObject(forKey: backgroundKey)
        customBackground = nil
        hasCustomBackground = false
    }
    
    // MARK: - Select Background
    
    func selectBackground() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.png, .jpeg, .heic]
        panel.message = "Select a background image"
        
        panel.begin { [weak self] response in
            guard response == .OK,
                  let url = panel.url,
                  let image = NSImage(contentsOf: url) else {
                return
            }
            
            self?.saveBackground(image)
        }
    }

    // MARK: - Reset Defaults
    
    func resetDefaults() {
        blurRadius = 150
        uiOpacity = 0.15
        customTextColor = .white
        customAccentColor = .white
        saveSettings()
    }
}

// Helper extension for Color to Hex conversion
extension Color {
    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
