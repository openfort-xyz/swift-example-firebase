# Openfort Firebase Authorization Example

This is a companion project to the [Openfort Swift SDK](https://github.com/openfort-xyz/swift-sdk).
It demonstrates integrating the Openfort embedded wallet with Firebase Authentication in a SwiftUI application.

## Overview

This example shows how to:

- Initialize the Openfort SDK with Firebase as the third-party auth provider
- Implement sign-in and sign-up flows (email/password, Apple Sign-In, OAuth, guest)
- Configure embedded wallet recovery (password-based or automatic)
- Manage multiple smart account wallets across chains
- Sign messages and EIP-712 typed data
- Link OAuth social accounts to a user profile
- Export private keys for wallet backup

## Setup

### 1. Create an Openfort Application

1. Sign up at [openfort.io](https://openfort.io)
2. Create a new project in your Openfort Dashboard
3. Copy your **Publishable Key** and **Shield Publishable Key** from the Developers section

### 2. Configure Firebase

1. Create a project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication with desired providers (Email/Password, Anonymous, Apple, Google)
3. Add an iOS app with bundle ID `com.openfort.noncustodial`
4. Download `GoogleService-Info.plist` and place it at:
   ```
   OpenfortAuthorization/GoogleService-Info.plist
   ```

### 3. Configure the Example

Open `OpenfortAuthorization/OFConfig.plist` and set:

- `openfortPublishableKey` - Your Openfort publishable key (required)
- `shieldPublishableKey` - Your Shield publishable key (required)
- `backendUrl` - Backend API base URL (optional)
- `shieldUrl` - Shield service URL (optional)
- `debug` - Enable debug logging (optional, boolean)

### 4. Run the App

1. Open `OpenfortFirebaseAuthorization.xcodeproj` in Xcode
2. Choose your target device or simulator (iOS 16.6+)
3. Build and run (⌘+R)
