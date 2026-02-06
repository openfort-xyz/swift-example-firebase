# Openfort Swift SDK - Firebase Example

A SwiftUI example application demonstrating [Openfort Swift SDK](https://github.com/openfort-xyz/swift-sdk) integration with Firebase Authentication. It showcases embedded wallet functionality, multiple authentication flows, transaction signing, and account recovery.

## Features

- **Authentication** - Email/password, Apple Sign-In, OAuth (Google, Twitter, Facebook), and guest login via Firebase Auth
- **Embedded Wallets** - Create and manage smart account wallets with automatic or password-based recovery
- **Message Signing** - Sign personal messages and EIP-712 typed data
- **OAuth Linking** - Link social accounts to an existing user profile
- **Private Key Export** - Export embedded wallet private keys for backup
- **Multi-Wallet Support** - Manage multiple wallets across chains

## Prerequisites

- Xcode 16.0+
- iOS 16.6+
- An [Openfort](https://openfort.io) account with a project created
- A [Firebase](https://console.firebase.google.com) project with Authentication enabled

## Setup

### 1. Configure Openfort

1. Sign up at [openfort.io](https://openfort.io)
2. Create a new project in your Openfort Dashboard
3. Copy your **Publishable Key** and **Shield Publishable Key** from the Developers section

### 2. Configure Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** with your desired sign-in providers (Email/Password, Anonymous, Apple, Google, etc.)
3. Add an iOS app to your Firebase project with bundle ID `com.openfort.noncustodial`
4. Download the `GoogleService-Info.plist` and place it at:
   ```
   OpenfortAuthorization/OpenfortAuthorization/GoogleService-Info.plist
   ```

### 3. Configure the App

Open `OpenfortAuthorization/OpenfortAuthorization/OFConfig.plist` and set:

| Key | Required | Description |
|-----|----------|-------------|
| `openfortPublishableKey` | Yes | Your Openfort publishable key (`pk_test_...`) |
| `shieldPublishableKey` | Yes | Your Shield publishable key |
| `backendUrl` | No | Backend API URL for server-side operations |
| `shieldUrl` | No | Custom Shield service URL |
| `debug` | No | Enable debug logging (`true`/`false`) |

### 4. Build & Run

```bash
# Open in Xcode
open OpenfortAuthorization/OpenfortFirebaseAuthorization.xcodeproj

# Or build from command line
xcodebuild -project OpenfortAuthorization/OpenfortFirebaseAuthorization.xcodeproj \
  -scheme OpenfortAuthorization -configuration Debug build
```

Select a simulator or device target and run (⌘+R).

## Project Structure

```
OpenfortAuthorization/OpenfortAuthorization/
├── OpenfortAuthorizationApp.swift    # @main entry point
├── AppDelegate.swift                 # Firebase & Openfort SDK initialization
├── LoginView.swift                   # Authentication entry point
├── RegisterView.swift                # User registration with email verification
├── ForgotPasswordView.swift          # Password reset request
├── ResetPasswordView.swift           # Password reset completion
├── HomeView.swift                    # Main authenticated dashboard
├── AccountRecoveryView.swift         # Wallet recovery configuration
├── WalletListView.swift              # Multi-wallet management
├── AccountActions/                   # Minting & transaction buttons
├── SessionKey/                       # Session key creation & management
├── Signatures/                       # Message & typed data signing
├── OAuth/                            # Social account linking
├── Export/                           # Private key export & wallet management
├── WalletConnect/                    # WalletConnect protocol integration
├── Funding/                          # Wallet funding flows
├── User/                             # User data display
├── WalletRecovery/                   # Recovery method management
└── Utils/                            # Shared utilities (SIWE, encryption, auth helpers)
```

## Architecture

The app follows a straightforward pattern:

1. **Firebase Auth** handles user authentication (email, OAuth, Apple, guest)
2. **AppDelegate** provides Firebase ID tokens to the Openfort SDK via a dynamic closure
3. **Openfort SDK** manages embedded wallets, signing, and blockchain interactions
4. **HomeView** reacts to `OFSDK.shared.embeddedStatePublisher` to show recovery setup, loading, or the full feature dashboard

## Dependencies

Managed via Swift Package Manager:

| Package | Version | Purpose |
|---------|---------|---------|
| [OpenfortSwift](https://github.com/openfort-xyz/swift-sdk) | main branch | Openfort SDK |
| [Firebase iOS SDK](https://github.com/firebase/firebase-ios-sdk) | 12.4.0 | Authentication |
| [Web3.swift](https://github.com/Boilertalk/Web3.swift) | 0.8.8 | Ethereum interactions |

## License

See the [Openfort Swift SDK](https://github.com/openfort-xyz/swift-sdk) repository for license details.
