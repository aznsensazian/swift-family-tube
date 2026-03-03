# Family Tube - Setup Guide

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- A Google Cloud Platform account

## Google Cloud Setup

### 1. Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project (e.g., "FamilyTube")
3. Enable the **Google Drive API**:
   - Navigate to **APIs & Services > Library**
   - Search for "Google Drive API" and enable it

### 2. Create OAuth 2.0 Credentials

1. Go to **APIs & Services > Credentials**
2. Click **Create Credentials > OAuth 2.0 Client ID**
3. Select **iOS** as the application type
4. Set the **Bundle ID** to: `com.familytube.app`
5. Copy the generated **Client ID**

### 3. Configure the App

Open `FamilyTube/FamilyTube/App/AppConstants.swift` and replace the placeholder values:

```swift
enum Google {
    static let clientID = "YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com"
    // ...
}
```

## Building & Running

1. Open `FamilyTube/FamilyTube.xcodeproj` in Xcode
2. Select your development team under **Signing & Capabilities**
3. Select an iPhone simulator or connected device
4. Press **Cmd + R** to build and run

## Architecture

```
FamilyTube/
├── App/                    # App entry point, constants
├── Models/                 # Data models (Video, User, ShareInvite)
├── Services/               # Google Auth, Google Drive, Thumbnail generation
├── ViewModels/             # Business logic (AuthViewModel, VideoViewModel)
├── Views/
│   ├── Auth/               # Sign-in screen
│   ├── Home/               # Home feed, search, explore, notifications
│   ├── Player/             # Video player with sharing
│   ├── Upload/             # Video upload flow
│   ├── Sharing/            # Email invite sharing
│   └── Profile/            # User profile, family management
├── Components/             # Reusable UI components
└── Resources/              # Assets, colors
```

## How It Works

### Authentication
- Uses Google OAuth 2.0 via `ASWebAuthenticationSession` (no third-party SDK needed)
- Tokens are stored locally and refreshed automatically

### Video Storage
- Videos are uploaded to a dedicated "FamilyTube Videos" folder in the user's Google Drive
- Metadata (title, description, sharing permissions, view counts) is stored as JSON files in a "FamilyTube Metadata" folder
- Thumbnails are auto-generated from videos and stored alongside them

### Privacy / Sharing
- Videos are **private by default** — only visible to the uploader
- Share with specific people by entering their email address
- Google Drive's native permission system controls file access
- "All Family" toggle makes a video visible to all family group members

### Offline
- The app requires an internet connection for video playback and uploads
- Metadata is fetched fresh on each app launch
