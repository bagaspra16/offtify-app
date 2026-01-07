//
//  CustomBackgroundView.swift
//  Offtify
//
//  Custom background with elegant blur effects
//

import SwiftUI

struct CustomBackgroundView: View {
    @ObservedObject var backgroundManager = BackgroundManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if backgroundManager.hasCustomBackground, let image = backgroundManager.customBackground {
                    // Dynamic Background Handling
                    if backgroundManager.blurRadius == 0 {
                        // Crystal Clear Mode (Wallpaper Style)
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } else {
                        // Abstract/Blur Mode
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .blur(radius: backgroundManager.blurRadius)
                            .scaleEffect(1.1) // Hide edges
                            .opacity(0.8)
                            .overlay(
                                // Subtle overlay for contrast in blur mode
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                } else {
                    // Default elegant gradient
                    LinearGradient(
                        colors: [
                            Color(hex: "FAFAFA"),
                            Color(hex: "F5F5F5"),
                            Color(hex: "EFEFEF")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: backgroundManager.hasCustomBackground)
    }
}

#Preview {
    CustomBackgroundView()
}
