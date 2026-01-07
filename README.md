# Offtify

<div align="center">

![Offtify Logo](https://img.shields.io/badge/Offtify-Premium%20Music-3A7BFF?style=for-the-badge&logo=apple&logoColor=white)

**The Ultimate Offline Music Experience for macOS**

*Premium Aesthetics • Zero-Latency Performance • Privacy First*

[![macOS](https://img.shields.io/badge/macOS-13.0+-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-FA7343?style=flat-square&logo=swift&logoColor=white)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

</div>

---

## Concept

**Offtify** is designed for the audiophile who values ownership, privacy, and design. In an era of streaming subscriptions, Offtify brings the focus back to *your* personal library. It is built natively for macOS with a philosophy of "Zero Compromise"—meaning no electron-bloat, no internet dependency, and absolutely no lag.

We combine the transparency and elegance of modern **Glassmorphism** with a highly optimized, multi-threaded audio engine to deliver a music player that feels like an extension of your operating system.

## Key Features

### Premium Full-Screen Experience
Immerse yourself in your music with a stunning, edge-to-edge player view.
- **Dynamic Adaptability**: Artwork and controls resize fluidly based on your window size.
- **Focus Mode**: Distraction-free listening with blurred dynamic backgrounds.
- **Gesture Control**: Intuitive drag-to-seek and smooth animations.

### Butter-Smooth Performance
Engineered for speed on Apple Silicon.
- **Decoupled Rendering Engine**: Playback progress is calculated independently from the UI thread, ensuring **60fps animations** even while scrolling through thousands of tracks.
- **Instant Search**: Find any track, album, or artist in milliseconds.
- **Native Efficiency**: Uses a fraction of the RAM compared to Electron-based players.

### Personalization & Aesthetics
Your music player should look as good as it sounds.
- **Glassmorphism Design**: Beautiful translucent layers that blend seamlessly with your wallpaper.
- **Custom Backgrounds**: Set your own vibes with support for custom background images.
- **Adaptive Themes**: UI elements extract and adapt colors from the currently playing album art.

### Core Capabilities
- **Universal Format Support**: MP3, FLAC, WAV, M4A, AAC, and AIFF.
- **Gapless Playback**: Seamless transitions for concept albums and live recordings.
- **Smart Queueing**: Drag & drop, shovel, and easy playlist management.
- **Background Mode**: Mini-player support for unobtrusive control.

---

## �️ Visual Tour

*(Place your screenshots here)*

| Library View | Immersive Player |
|:---:|:---:|
| *Browse your collection with style* | *Focus on what matters—the music* |

---

## Installation

**Offtify** is distributed as a standalone macOS application.

### Option 1: Build from Source
Perfect for developers who want to tinker.
```bash
git clone https://github.com/yourusername/offtify-app.git
cd offtify-app
open Offtify.xcodeproj
# Press Cmd + R to build
```

### Option 2: Standalone App
1. Download the latest release.
2. Drag `Offtify.app` to your `Applications` folder.
3. Launch via Spotlight or Launchpad.

---

## Technical Architecture

Offtify isn't just a pretty face; it's robustly engineered.

- **Frontend**: 100% SwiftUI with complex Custom Layouts (`GeometryReader`, `ZStack` layering).
- **State Management**: Advanced `Combine` architecture separating **High-Frequency** (Progress, roughly 60Hz) from **Low-Frequency** (Metadata, Play State) signals to eliminate rect-redraw bottlenecks.
- **Audio Engine**: Custom wrapper around `AVQueuePlayer` for low-latency playback.

---

## Shortcuts

| Action | Shortcut |
|--------|----------|
| **Play/Pause** | `Space` |
| **Next Track** | `Cmd + →` |
| **Previous Track** | `Cmd + ←` |
| **Volume Up/Down** | `Cmd + ↑ / ↓` |
| **Shuffle** | `Cmd + S` |
| **Repeat** | `Cmd + R` |
| **Enter Full Screen** | `Cmd + F` |

---

<div align="center">

**Rediscover Your Library.**

Made with ❤️ by [bagaspra16](https://bagaspra16-portfolio.vercel.app/) • [Contact](mailto:bagaspratamajunianika72@gmail.com)

</div>
