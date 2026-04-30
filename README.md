# Music App - Audio Player & Discovery Platform

## Overview
A comprehensive music application featuring audio playback, library management, and music discovery features. Stream your favorite tracks with a clean, modern interface.

## Features (MVP)
- 🎵 Audio playback controls
- 📚 Music library organization
- 🔍 Search functionality
- ♫ Playlists management
- 🔄 Background playback support
- 🎨 Customizable player interface
- 🌙 Dark/Light theme support
- 🎶 Volume and speed controls

## Planned Features (Phase 2)
- 👥 Social sharing and collaboration
- 📰 Music news and recommendations
- ⭐ Artist profiles
- 🏆 Play statistics and achievements
- 💿 Album art caching
- 📱 Notification center integration

## Getting Started

### Prerequisites
- [Flutter](https://flutter.dev) SDK >= 3.5.0
- [Dart](https://dart.dev) SDK >= 3.5.0

### Installation
```bash
git clone https://github.com/govind/music_app.git
cd music_app
flutter pub get
flutter run
```

### Development
```bash
# Run on device or emulator
flutter run -d <device_id>

# Debug mode
flutter run --debug

# Hot reload for quick iteration
flutter run
```

## Project Structure
```
music_app/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── models/                    # Data models
│   │   └── song.dart              # Song data model
│   ├── screens/                   # UI screens
│   │   ├── home_screen.dart       # Main dashboard
│   │   ├── player_screen.dart     # Audio player UI
│   │   ├── library_screen.dart    # Music library
│   │   └── search_screen.dart     # Search interface
│   ├── services/                  # Business logic
│   │   ├── audio_service.dart     # Audio playback
│   │   └── music_provider.dart    # Data fetching
│   └── widgets/                   # Reusable components
├── pubspec.yaml                  # Dependencies and metadata
├── analysis_options.yaml         # Linting rules
└── README.md                    # This file
```

## Audio Service
The app uses Flutter's audio_player package for robust background playback:
- Plays music even when app is in background
- Lock screen controls
- Picture-in-picture mode support
- Persistent audio session

## Dependencies
Key packages (from pubspec.yaml):
- `audio_player`: Core playback functionality
- `provider`: State management
- Additional UI and utility packages as needed

## Contributing
Pull requests are welcome! Please open an issue first to discuss major changes.

## License
MIT License - See LICENSE file for details.
