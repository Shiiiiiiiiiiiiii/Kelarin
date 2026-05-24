# Firebase Setup Guide

This guide will help you set up Firebase for the Kelarin project.

## Prerequisites

- A Google account
- Firebase CLI (optional but recommended)
- Google Cloud Platform (GCP) account

## Step-by-Step Setup

### 1. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "Kelarin" (or your preferred name)
4. Choose analytics settings (optional)
5. Click "Create project"

### 2. Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click **Get Started**
3. Enable the following sign-in methods:
   - **Email/Password**: Click enable, then enable email/password
   - **Google**: Click enable, add your support email and app name
4. Save changes

### 3. Create Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Choose a region (closest to your users)
4. Start in **Test mode** (for development)
5. Click **Create**

### 4. Android Setup

1. In Firebase Console, click **Project Settings** (⚙️)
2. Click **Project Settings** tab
3. Click **Add App** and select **Android**
4. Enter package name: `com.example.kelarin` (check your `android/app/build.gradle.kts`)
5. Optional: Add SHA-1 fingerprint (get with: `keytool -list -v -keystore ~/.android/debug.keystore`)
6. Click **Register app**
7. Download `google-services.json`
8. Copy it to `android/app/`

### 5. iOS Setup (Optional)

1. In Firebase Console, click **Add App** and select **iOS**
2. Enter bundle ID (check Xcode: Runner > Runner > General)
3. Register app
4. Download `GoogleService-Info.plist`
5. Open Xcode: `open ios/Runner.xcworkspace`
6. Add the .plist file to the Runner project
7. Add it to all targets

### 6. Web Setup (Optional)

For web builds, you'll need web configuration:

1. In Firebase Console, click **Add App** and select **Web**
2. Register and copy the Firebase config
3. Add to your web app initialization

## Important Security Rules

### Development (Test Mode)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Production (Secure Mode)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    match /tasks/{taskId} {
      allow read, write: if 
        request.auth.uid == resource.data.userId ||
        request.auth.uid == request.resource.data.userId;
    }
  }
}
```

## Environment Variables

Create a `.env` file in the project root (NOT committed to Git):

```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-web-api-key
FIREBASE_APP_ID=your-app-id
```

## Testing Firebase Locally

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Initialize Firebase:
   ```bash
   firebase init
   ```

3. Start emulator:
   ```bash
   firebase emulators:start
   ```

## Troubleshooting

### APK/App still not signing in
- Verify `google-services.json` is in `android/app/`
- Check package name matches Firebase setup
- Run `flutter clean` and rebuild

### iOS issues
- Ensure `GoogleService-Info.plist` is added to Xcode
- Check all targets have the file
- Run `pod install` in ios directory

### Firestore permission denied
- Check Firebase security rules
- Verify user is authenticated
- Check user UID in Firestore

## Next Steps

1. Update `.env` with your Firebase credentials
2. Configure Firestore security rules for production
3. Set up Google Cloud Platform billing (if needed)
4. Enable any additional services (Cloud Functions, Storage, etc.)

## Resources

- [Firebase Flutter Setup](https://firebase.flutter.dev/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
