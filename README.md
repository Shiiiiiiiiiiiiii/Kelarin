# Kelarin - Focus Timer & Task Management App

A Flutter-based productivity application that combines a focus timer (Pomodoro-style) with task management, featuring strict mode, audio notifications, and Firebase integration.

## Features

- ⏱️ **Focus Timer** - Customizable Pomodoro-style timer with visual progress indicator
- 📋 **Task Management** - Create, track, and manage your daily tasks
- 🔒 **Strict Mode** - Disable pause functionality for deep focus sessions
- 🎵 **Audio Notifications** - Sound alerts when focus sessions complete
- 🌙 **Dark Mode Support** - Full theme support for day and night modes
- 🔐 **Authentication** - Firebase Authentication with Google Sign-In
- ☁️ **Cloud Sync** - Cloud Firestore for task synchronization across devices
- 📍 **Timezone Support** - Automatic timezone detection and management
- 💾 **Persistent Storage** - Local preferences and settings backup

## Tech Stack

- **Framework**: Flutter 3.11+
- **State Management**: Riverpod
- **Backend**: Firebase (Auth, Firestore)
- **Notifications**: Flutter Local Notifications
- **Audio**: Audioplayers
- **Local Storage**: Shared Preferences
- **Timezone**: Flutter Timezone

## Prerequisites

- Flutter SDK: >=3.11.0
- Dart SDK: >=3.11.0
- Android SDK (for Android builds)
- Xcode (for iOS builds)
- Firebase project setup

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/kelarin.git
   cd kelarin
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase**
   - Download `google-services.json` for Android from Firebase Console
   - Place it in `android/app/`
   - For iOS, download `GoogleService-Info.plist` and add it to Xcode

4. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/                 # Core utilities, constants, themes
├── features/
│   ├── auth/            # Authentication feature
│   ├── focus/           # Focus timer feature
│   ├── task/            # Task management feature
│   └── ...
├── shared/              # Shared widgets and utilities
└── main.dart           # App entry point
```

## Configuration

### Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Enable these services:
   - Authentication (Email/Password, Google Sign-In)
   - Firestore Database
   - Cloud Messaging (for notifications)

4. Download configuration files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → Add to Xcode project

### Environment Variables

Create a `.env` file in the root directory (not committed):
```
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_WEB_API_KEY=your_web_api_key
```

> ⚠️ Never commit sensitive files like `google-services.json`, `local.properties`, or `.env` files

## Building

### Android
```bash
flutter build apk --release
# or AAB for Play Store
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Development

### Run with debug output
```bash
flutter run -v
```

### Run tests
```bash
flutter test
```

### Analyze code
```bash
flutter analyze
```

### Format code
```bash
dart format lib/
```

## Git Workflow

This project uses Git for version control. Important notes:

- Sensitive files are in `.gitignore` - never commit credentials
- Use `.gitattributes` for cross-platform line endings
- Follow conventional commits for clarity

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing issues for solutions
- Provide detailed reproduction steps

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Riverpod community for state management
- All contributors and supporters

---

**Last Updated**: May 2026
**Author**: Your Name/Organization
