//
//  Theme.swift
//  Offtify
//
//  Design system and color palette
//

import SwiftUI

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Colors

struct Theme {
    // MARK: - Base Colors (White Theme)
    
    /// Main background: Pure white with slight warmth
    static let backgroundPrimary = Color(hex: "FAFAFA")
    
    /// Secondary background: Soft white glass
    static var backgroundSecondary: Color {
        Color.white.opacity(BackgroundManager.shared.uiOpacity)
    }
    
    /// Card/Surface background: Glassmorphism white
    static var surface: Color {
        Color.white.opacity(BackgroundManager.shared.uiOpacity + 0.05)
    }
    
    /// Elevated surface: More opaque glassmorphism
    static var surfaceElevated: Color {
        Color.white.opacity(BackgroundManager.shared.uiOpacity + 0.15)
    }
    
    /// Glassmorphism blur surface
    static var surfaceGlass: Color {
        Color.white.opacity(BackgroundManager.shared.uiOpacity)
    }
    
    // MARK: - Accent Colors (Elegant & Minimal)
    
    /// Primary accent: Elegant dark gray
    static var accentPrimary: Color {
        BackgroundManager.shared.customAccentColor
    }
    
    /// Soft accent: Medium gray
    static let accentSoft = Color(hex: "4A4A4A")
    
    /// Muted accent: Light gray
    static let accentMuted = Color(hex: "8E8E8E")
    
    /// Highlight: Subtle blue for interactive elements
    static let accentHighlight = Color(hex: "5B9FFF")
    
    /// Deep accent: Almost black
    static let accentDeep = Color(hex: "1A1A1A")
    
    // MARK: - Text Colors (Dark on Light)
    
    /// Primary text: Dark gray
    static var textPrimary: Color {
        BackgroundManager.shared.customTextColor
    }
    
    /// Secondary text: Medium opacity
    static var textSecondary: Color {
        Theme.textPrimary.opacity(0.7)
    }
    
    /// Tertiary text: Low opacity
    static var textTertiary: Color {
        Theme.textPrimary.opacity(0.5)
    }
    
    /// Muted text: Very low opacity
    static var textMuted: Color {
        Theme.textPrimary.opacity(0.3)
    }
    
    // MARK: - Gradients (White Theme)
    
    /// Main accent gradient: Elegant dark gradient
    static var gradientAccent: LinearGradient {
        LinearGradient(
            colors: [
                BackgroundManager.shared.customAccentColor,
                BackgroundManager.shared.customAccentColor.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Subtle background gradient: Light to lighter
    static let gradientBackground = LinearGradient(
        colors: [
            Color(hex: "FAFAFA"),
            Color(hex: "F5F5F5")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Progress bar gradient: Subtle gray
    static let gradientProgress = LinearGradient(
        colors: [
            Color(hex: "4A4A4A"),
            Color(hex: "2C2C2C")
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Card glow gradient: Soft shadow
    static let gradientGlow = RadialGradient(
        colors: [
            Color.black.opacity(0.05),
            Color.clear
        ],
        center: .center,
        startRadius: 0,
        endRadius: 200
    )
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }
    
    // MARK: - Shadows
    
    struct Shadow {
        static let soft = Color.black.opacity(0.3)
        static let glow = Color(hex: "3A7BFF").opacity(0.4)
    }
    
    // MARK: - Animation
    
    struct Animation {
        /// Standard ease-out animation
        static let standard = SwiftUI.Animation.easeOut(duration: 0.2)
        
        /// Smooth transition
        static let smooth = SwiftUI.Animation.easeOut(duration: 0.3)
        
        /// Quick response
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        
        /// Hover scale
        static let hoverScale: CGFloat = 1.02
        
        /// Press scale
        static let pressScale: CGFloat = 0.96
    }
}

// MARK: - View Modifiers

struct GlassmorphismModifier: ViewModifier {
    var cornerRadius: CGFloat = Theme.Radius.lg
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct SoftShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Theme.Shadow.soft, radius: 20, x: 0, y: 10)
    }
}

struct GlowModifier: ViewModifier {
    var color: Color = Theme.accentPrimary
    var radius: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.4), radius: radius, x: 0, y: 0)
    }
}

extension View {
    func glassmorphism(cornerRadius: CGFloat = Theme.Radius.lg) -> some View {
        modifier(GlassmorphismModifier(cornerRadius: cornerRadius))
    }
    
    func softShadow() -> some View {
        modifier(SoftShadowModifier())
    }
    
    func glow(color: Color = Theme.accentPrimary, radius: CGFloat = 20) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.gradientAccent)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .scaleEffect(configuration.isPressed ? Theme.Animation.pressScale : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.surface)
            .foregroundColor(Theme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(Theme.textMuted, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? Theme.Animation.pressScale : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 36
    var showBackground: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(showBackground ? Theme.surface : Color.clear)
            .foregroundColor(Theme.textPrimary)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? Theme.Animation.pressScale : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

struct PlayButtonStyle: ButtonStyle {
    var isPlaying: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 56, height: 56)
            .background(Theme.gradientAccent)
            .foregroundColor(.white)
            .clipShape(Circle())
            .glow()
            .scaleEffect(configuration.isPressed ? Theme.Animation.pressScale : 1.0)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
