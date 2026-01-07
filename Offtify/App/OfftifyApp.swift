//
//  OfftifyApp.swift
//  Offtify
//
//  A native macOS music player
//

import SwiftUI

@main
struct OfftifyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            // Playback Commands
            CommandMenu("Playback") {
                Button("Play/Pause") {
                    AudioPlayerService.shared.togglePlayPause()
                }
                .keyboardShortcut(.space, modifiers: [])
                
                Button("Next Track") {
                    AudioPlayerService.shared.next()
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)
                
                Button("Previous Track") {
                    AudioPlayerService.shared.previous()
                }
                .keyboardShortcut(.leftArrow, modifiers: .command)
                
                Divider()
                
                Button("Volume Up") {
                    let newVolume = min(AudioPlayerService.shared.volume + 0.1, 1.0)
                    AudioPlayerService.shared.volume = newVolume
                }
                .keyboardShortcut(.upArrow, modifiers: .command)
                
                Button("Volume Down") {
                    let newVolume = max(AudioPlayerService.shared.volume - 0.1, 0.0)
                    AudioPlayerService.shared.volume = newVolume
                }
                .keyboardShortcut(.downArrow, modifiers: .command)
            }
            
            // Library Commands
            CommandMenu("Library") {
                Button("Select Music Folder...") {
                    Task { @MainActor in
                        _ = MusicLibraryService.shared.selectMusicFolder()
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Rescan Library") {
                    // This will be handled by the view model
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure the main window
        if let window = NSApplication.shared.windows.first {
            configureWindow(window)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up audio player
        AudioPlayerService.shared.stop()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    private func configureWindow(_ window: NSWindow) {
        // Set window appearance
        window.backgroundColor = NSColor(Color(hex: "0B0F1A"))
        window.isMovableByWindowBackground = true
        
        // Configure title bar
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        // Set window style
        window.styleMask.insert(.fullSizeContentView)
        
        // Configure traffic light buttons
        if let closeButton = window.standardWindowButton(.closeButton) {
            closeButton.superview?.frame.origin.y = 0
        }
        
        // Set minimum size
        window.minSize = NSSize(width: 1000, height: 700)
        
        // Center on screen
        window.center()
    }
}

// MARK: - Window Access Key

struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
