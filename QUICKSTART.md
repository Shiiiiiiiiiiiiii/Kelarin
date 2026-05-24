# Quick Start Guide for Developers

Welcome to Kelarin! This guide will get you up and running in minutes.

## Prerequisites

Ensure you have the following installed:
- Flutter SDK 3.11+
- Dart SDK 3.11+
- Android Studio or Xcode (for emulators)
- Git

**Verify installation:**
```bash
flutter --version
dart --version
git --version
```

## Clone the Repository

```bash
git clone https://github.com/yourusername/kelarin.git
cd kelarin
```

## Setup Firebase

This app requires Firebase. Follow these steps:

1. **Create Firebase Project** (if needed)
   - Visit [Firebase Console](https://console.firebase.google.com/)
   - See `FIREBASE_SETUP.md` for detailed instructions

2. **Add Firebase Configuration Files**
   - Android: Download `google-services.json` → `android/app/`
   - iOS: Download `GoogleService-Info.plist` → Add to Xcode

3. **Create Environment File**
   ```bash
   # Create .env file in project root (DO NOT COMMIT)
   echo "FIREBASE_PROJECT_ID=your_project_id" > .env
   ```

## Install Dependencies

```bash
# Get all pub packages
flutter pub get

# For iOS, also run
cd ios
pod install
cd ..
```

## Run the App

### Android
```bash
# List available Android devices
flutter devices

# Run on emulator
flutter run

# Build APK
flutter build apk --release
```

### iOS
```bash
# List available iOS devices
flutter devices

# Run on simulator
flutter run

# Build iOS app
flutter build ios --release
```

### Web (if enabled)
```bash
# Run on web
flutter run -d chrome

# Build web
flutter build web
```

## Development Workflow

### Code Formatting
```bash
# Format all Dart files
dart format lib/

# Check formatting
dart format --set-exit-if-changed lib/
```

### Code Analysis
```bash
# Analyze code for issues
flutter analyze lib/

# Fix auto-fixable issues
dart fix --apply lib/
```

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/focus/

# Run with coverage
flutter test --coverage
```

### Hot Reload During Development
```bash
# Press 'r' in terminal for hot reload
# Press 'R' for full restart
flutter run
```

## Project Structure

```
lib/
├── core/               # Shared utilities, constants, themes
├── features/           # Feature modules
│   ├── auth/          # Authentication
│   ├── focus/         # Focus timer (main feature)
│   ├── task/          # Task management
│   └── settings/      # App settings (if applicable)
├── shared/            # Shared widgets and utilities
└── main.dart         # App entry point
```

## Common Tasks

### Add a New Package
```bash
flutter pub add package_name

# Or for dev dependencies
flutter pub add --dev package_name
```

### Update Dependencies
```bash
# Check for updates
flutter pub outdated

# Update all
flutter pub upgrade

# Update to latest major versions
flutter pub upgrade --major-versions
```

### Generate Code (if using build_runner)
```bash
# Generate code once
flutter pub run build_runner build

# Watch mode (regenerate on file changes)
flutter pub run build_runner watch
```

### Clean Everything
```bash
flutter clean
flutter pub get
cd ios && rm -rf Pods && pod install && cd ..
```

## Troubleshooting

### Build Issues
```bash
# Full clean and rebuild
flutter clean
flutter pub get
flutter run

# Or on iOS
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run
```

### Firebase Connection Issues
- Verify `google-services.json` is in `android/app/`
- Check package name matches Firebase console
- Ensure Firebase project exists and is configured
- See `FIREBASE_SETUP.md` for detailed troubleshooting

### Emulator Issues
```bash
# iOS
open -a Simulator

# Android
emulator @device_name

# Or use Flutter
flutter emulators --launch <emulator_id>
```

### Dependency Conflicts
```bash
# Get pub.dev dependency info
flutter pub deps

# Check for outdated
flutter pub outdated

# Try pub upgrade
flutter pub upgrade
```

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature

# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Push to remote
git push origin feature/your-feature

# Create pull request on GitHub
```

## Code Review Checklist

Before committing:
- [ ] Code follows style guide
- [ ] `dart format` has been run
- [ ] `flutter analyze` shows no errors
- [ ] Tests pass: `flutter test`
- [ ] No debug print statements
- [ ] No hardcoded values
- [ ] Comments added for complex logic

## IDE Setup

### VS Code
1. Install "Flutter" extension by Dart Code
2. Install "Dart" extension by Dart Code
3. Restart VS Code
4. Open command palette (Ctrl+Shift+P)
5. Run "Flutter: New Project" or open existing

### Android Studio
1. Install Flutter and Dart plugins
2. File > Open > Select project folder
3. Run > Run 'main.dart'

### IntelliJ IDEA
Same as Android Studio

## Performance Optimization

- Use `flutter run --profile` for performance testing
- Use DevTools: `flutter pub global activate devtools && devtools`
- Profile with: `flutter run --profile`

## Documentation

- 📖 [Flutter Docs](https://docs.flutter.dev/)
- 📖 [Dart Docs](https://dart.dev/guides)
- 📖 [Riverpod Docs](https://riverpod.dev/)
- 📖 [Firebase Flutter](https://firebase.flutter.dev/)

## Getting Help

1. Check `README.md` for project info
2. See `CONTRIBUTING.md` for guidelines
3. Review `FIREBASE_SETUP.md` for Firebase issues
4. Search [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
5. Check [GitHub Issues](https://github.com/yourusername/kelarin/issues)

## Need More Help?

- ✅ Open an issue on GitHub
- ✅ Check existing issues
- ✅ Join Flutter community
- ✅ Check Flutter Discord

## What's Next?

1. ✅ Set up Firebase (FIREBASE_SETUP.md)
2. ✅ Run the app
3. ✅ Explore the codebase
4. ✅ Make your first change
5. ✅ Submit a pull request!

---

Happy coding! 🚀

**Questions?** Check the docs or open an issue!
