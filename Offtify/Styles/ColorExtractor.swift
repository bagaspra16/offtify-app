//
//  ColorExtractor.swift
//  Offtify
//
//  Extracts dominant colors from artwork for dynamic gradients
//

import Foundation
import AppKit
import SwiftUI

/// Utility for extracting dominant colors from images
struct ColorExtractor {
    
    // MARK: - Color Result
    
    struct DominantColors {
        let primary: Color
        let secondary: Color
        let accent: Color
        let isDark: Bool
        
        /// Create gradient from colors
        var gradient: LinearGradient {
            LinearGradient(
                colors: [primary, secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        /// Background gradient with fade to black
        var backgroundGradient: LinearGradient {
            LinearGradient(
                colors: [
                    primary.opacity(0.8),
                    secondary.opacity(0.6),
                    Color(hex: "0B0F1A")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        
        /// Radial gradient centered on artwork
        var radialGradient: RadialGradient {
            RadialGradient(
                colors: [
                    primary.opacity(0.9),
                    secondary.opacity(0.5),
                    Color(hex: "0B0F1A").opacity(0.9)
                ],
                center: .center,
                startRadius: 50,
                endRadius: 500
            )
        }
        
        static let `default` = DominantColors(
            primary: Color(hex: "1A2B6F"),
            secondary: Color(hex: "0B0F1A"),
            accent: Color(hex: "3A7BFF"),
            isDark: true
        )
    }
    
    // MARK: - Extraction
    
    /// Extract dominant colors from an NSImage
    static func extractColors(from image: NSImage?) -> DominantColors {
        guard let image = image,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .default
        }
        
        // Resize image for faster processing
        let size = CGSize(width: 50, height: 50)
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width) * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        guard let data = context?.data else {
            return .default
        }
        
        let pointer = data.bindMemory(to: UInt8.self, capacity: Int(size.width) * Int(size.height) * 4)
        
        var colorCounts: [String: (count: Int, r: Int, g: Int, b: Int)] = [:]
        
        // Sample pixels
        for y in stride(from: 0, to: Int(size.height), by: 2) {
            for x in stride(from: 0, to: Int(size.width), by: 2) {
                let offset = (y * Int(size.width) + x) * 4
                let r = Int(pointer[offset])
                let g = Int(pointer[offset + 1])
                let b = Int(pointer[offset + 2])
                
                // Quantize colors to reduce variations
                let qr = (r / 32) * 32
                let qg = (g / 32) * 32
                let qb = (b / 32) * 32
                
                let key = "\(qr),\(qg),\(qb)"
                
                if let existing = colorCounts[key] {
                    colorCounts[key] = (existing.count + 1, qr, qg, qb)
                } else {
                    colorCounts[key] = (1, qr, qg, qb)
                }
            }
        }
        
        // Sort by frequency
        let sortedColors = colorCounts.values
            .sorted { $0.count > $1.count }
            .filter { color in
                // Filter out very dark and very light colors
                let brightness = (color.r + color.g + color.b) / 3
                return brightness > 20 && brightness < 240
            }
        
        guard sortedColors.count >= 2 else {
            return .default
        }
        
        let primaryColor = sortedColors[0]
        let secondaryColor = sortedColors.count > 1 ? sortedColors[1] : sortedColors[0]
        let accentColor = sortedColors.count > 2 ? sortedColors[2] : primaryColor
        
        let primary = Color(
            red: Double(primaryColor.r) / 255.0,
            green: Double(primaryColor.g) / 255.0,
            blue: Double(primaryColor.b) / 255.0
        )
        
        let secondary = Color(
            red: Double(secondaryColor.r) / 255.0,
            green: Double(secondaryColor.g) / 255.0,
            blue: Double(secondaryColor.b) / 255.0
        )
        
        let accent = Color(
            red: Double(accentColor.r) / 255.0,
            green: Double(accentColor.g) / 255.0,
            blue: Double(accentColor.b) / 255.0
        )
        
        // Determine if image is dark
        let avgBrightness = (primaryColor.r + primaryColor.g + primaryColor.b) / 3
        let isDark = avgBrightness < 128
        
        return DominantColors(
            primary: primary,
            secondary: secondary,
            accent: accent,
            isDark: isDark
        )
    }
    
    /// Extract colors from artwork data
    static func extractColors(from artworkData: Data?) -> DominantColors {
        guard let data = artworkData,
              let image = NSImage(data: data) else {
            return .default
        }
        return extractColors(from: image)
    }
}
