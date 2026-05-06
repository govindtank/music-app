# 🎵 Music App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.24.0-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.5.0-0175C2?style=for-the-badge&logo=dart)
![Material](https://img.shields.io/badge/Material%20Design-3-757DE8?style=for-the-badge&logo=material-design)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Deployed-222?style=for-the-badge&logo=github)

**🎶 A beautiful Flutter music player app with a rich purple/deep blue theme**

**[Live Demo](https://govindtank.github.io/music-app/)** | **[Report Bug](https://github.com/govindtank/music-app/issues)**

</div>

---

## ✨ Features

### 🎵 Core Features
- **Home Screen** - Discover music with featured sections and categories
- **Favorites** - Save and manage your favorite tracks
- **Downloads** - Offline access to downloaded tracks
- **Library** - Browse and manage your playlists

### 🎨 UI/UX Features
- **Rich Purple/Deep Blue Theme** - Beautiful music app aesthetic
- **Animated Splash Screen** - Smooth app launch experience
- **Polished Bottom Navigation** - Modern, animated navigation bar
- **Smooth Page Transitions** - Seamless navigation experience
- **Responsive Design** - Works great on web and mobile
- **Shimmer Loading Effects** - Elegant loading states
- **Card-based Track Lists** - Beautiful track item styling

### 🛠 Technical Features
- **Material Design 3** - Modern, consistent design system
- **State Management** - Bloc pattern for clean architecture
- **Audio Service Integration** - Full audio playback support
- **Cached Network Images** - Efficient image loading
- **Responsive Sizing** - Adaptive layouts with responsive_sizer

---

## 📸 Screenshots

| Home | Favorites | Downloads | Library |
|:----:|:---------:|:---------:|:--------:|
| ![Home](https://via.placeholder.com/300x600/1A1A2E/9C27B0?text=Home) | ![Favorites](https://via.placeholder.com/300x600/1A1A2E/E91E63?text=Favorites) | ![Downloads](https://via.placeholder.com/300x600/1A1A2E/4CAF50?text=Downloads) | ![Library](https://via.placeholder.com/300x600/1A1A2E/9C27B0?text=Library) |

---

## 🏗️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.24.0 |
| **Language** | Dart 3.5.0 |
| **State Management** | flutter_bloc |
| **Audio** | audio_service |
| **Design** | Material Design 3 |
| **Images** | cached_network_image |
| **Responsive** | responsive_sizer |
| **DI** | get_it |
| **CI/CD** | GitHub Actions |

---

## 📁 Project Structure

```
music-app/
├── lib/
│   ├── main.dart                 # App entry point with UI
│   ├── bloc/
│   │   └── track_list_bloc.dart # Track list state management
│   ├── screens/
│   │   └── now_playing_screen.dart
│   ├── services/
│   │   ├── audio_service.dart
│   │   ├── api_service.dart
│   │   ├── database_service.dart
│   │   └── data_initialization_service.dart
│   ├── utils/
│   │   └── position_data.dart
│   └── widgets/
│       ├── miniplayer.dart
│       └── enhanced_track_list.dart
├── build/
│   └── web/                     # Production build output
├── .github/
│   └── workflows/
│       └── deploy.yml           # CI/CD workflow
├── pubspec.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.24.0 or higher
- Dart SDK 3.5.0 or higher

### Installation

```bash
# Clone the repository
git clone https://github.com/govindtank/music-app.git
cd music-app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build for Web

```bash
# Build release
flutter build web --release --base-href /music-app/

# Serve locally
cd build/web
python3 -m http.server 8080
```

---

## 🌐 Deployment

The app is automatically deployed to GitHub Pages using GitHub Actions on every push to `main`.

### Manual Deployment

```bash
# Build the web app
flutter build web --release --base-href /music-app/

# Deploy to GitHub Pages
# Push the build/web folder to gh-pages branch
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Govind Tank**
- GitHub: [@govindtank](https://github.com/govindtank)
- Email: govindtank600@gmail.com

---

<div align="center">

**⭐ Star this repo if you find it helpful!**

Made with ❤️ using Flutter

</div>
