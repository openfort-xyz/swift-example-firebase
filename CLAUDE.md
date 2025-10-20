# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI example application demonstrating the Openfort Swift SDK integration. It showcases embedded wallet functionality, authentication flows (email/password, OAuth, guest, Apple Sign-In), wallet management, transaction signing, and account recovery mechanisms.

## Build & Run Commands

### Build the Project
```bash
xcodebuild -project OpenfortAuthorization/OpenfortAuthorization.xcodeproj -scheme OpenfortAuthorization -configuration Debug build
```

### Run Tests
```bash
# Run all tests
xcodebuild test -project OpenfortAuthorization/OpenfortAuthorization.xcodeproj -scheme OpenfortAuthorization -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test target
xcodebuild test -project OpenfortAuthorization/OpenfortAuthorization.xcodeproj -scheme OpenfortAuthorization -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:OpenfortAuthorizationTests

# Run UI tests
xcodebuild test -project OpenfortAuthorization/OpenfortAuthorization.xcodeproj -scheme OpenfortAuthorization -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:OpenfortAuthorizationUITests
```

### Clean Build
```bash
xcodebuild clean -project OpenfortAuthorization/OpenfortAuthorization.xcodeproj -scheme OpenfortAuthorization
```

## Configuration

### OFConfig.plist
The app requires configuration via `OpenfortAuthorization/OpenfortAuthorization/OFConfig.plist`:
- `backendUrl` - Backend API URL (optional)
- `iframeUrl` - Iframe environment URL (optional)
- `openfortPublishableKey` - Openfort publishable key (required)
- `shieldPublishableKey` - Shield publishable key (required)
- `shieldUrl` - Shield service URL (optional)
- `debug` - Enable debug logging (boolean)

### GoogleService-Info.plist
Firebase configuration required for Firebase Authentication integration at `OpenfortAuthorization/OpenfortAuthorization/GoogleService-Info.plist`.

## Architecture

### SDK Initialization Flow
1. **AppDelegate.swift** - Firebase and Openfort SDK initialization happens in `application(_:didFinishLaunchingWithOptions:)`
   - Firebase is configured first with `FirebaseApp.configure()`
   - Openfort SDK is set up with third-party Firebase auth support using `OFSDK.setupSDK(thirdParty: .firebase)`
   - The SDK receives a closure that dynamically fetches Firebase ID tokens when needed

### Authentication Flow
1. **LoginView** - Entry point, handles multiple auth methods:
   - Email/password authentication via Firebase Auth
   - OAuth (Google, Twitter, Facebook) via `OFSDK.shared.initOAuth()`
   - Apple Sign-In using `SignInWithAppleButton` and ASAuthorization
   - Guest sign-up via `OFSDK.shared.signUpGuest()`
   - Wallet Connect authentication
   - Session restoration via `OFSDK.shared.getUser()` on app launch

2. **Firebase Integration** - Firebase Auth is the authentication backend:
   - User authenticates with Firebase first
   - Firebase ID token is automatically provided to Openfort SDK via the closure set in AppDelegate
   - Openfort SDK uses the token for subsequent API calls

3. **OAuth Flow** - OAuth providers use deep linking:
   - `initOAuth()` generates authorization URL with redirect URI
   - App opens URL in external browser
   - User completes OAuth flow
   - Redirect URL (scheme: `openfortios://login`) brings user back to app
   - URL contains `access_token`, `refresh_token`, and `player_id` query parameters
   - Credentials are stored via `OFSDK.shared.storeCredentials()`

### Embedded Wallet States
The app tracks embedded wallet state via `OFSDK.shared.embeddedStatePublisher`:
- `.none` - No wallet configured
- `.embeddedSignerNotConfigured` - User authenticated but wallet needs recovery setup
- `.creatingAccount` - Account creation in progress
- `.ready` - Wallet fully configured and operational

### Account Recovery System
**AccountRecoveryView** provides two recovery methods:

1. **Password Recovery** - User provides a password to secure wallet recovery:
   - Password is passed to `OFSDK.shared.configure()` with `recoveryMethod: .password`
   - Configuration includes `chainId` and recovery parameters

2. **Automatic Recovery** - Uses server-side encryption session:
   - Fetches encryption session from backend API (`getEncryptionSession()`)
   - Session string passed to `OFSDK.shared.configure()` with `recoveryMethod: .automatic`
   - Backend endpoint: `https://openfort-auth-non-custodial.vercel.app/api/protected-create-encryption-session`

### Component Organization
- **AccountActions/** - Transaction and blockchain interaction buttons (minting, etc.)
- **SessionKey/** - Session key creation and management
- **Signatures/** - Message and typed data signing components
- **OAuth/** - Social login linking and management
- **Export/** - Private key export and embedded wallet management
- **WalletConnect/** - WalletConnect protocol integration
- **Funding/** - Wallet funding flows
- **Utils/** - Shared utilities:
  - `SIWE.swift` - Sign-In With Ethereum message generation
  - `EncriptionSession.swift` - Backend API call for encryption sessions
  - `AppleAuthManager.swift` - Apple authentication and biometric helpers
  - `RedirectManager.swift` - Deep link management

### HomeView Architecture
**HomeView** serves as the main authenticated interface with different states:
1. Shows `AccountRecoveryView` when `state == .embeddedSignerNotConfigured`
2. Displays loading UI when `state == .creatingAccount`
3. Shows full feature panels when `state == .ready`:
   - Account actions
   - Signatures panel
   - Linked socials
   - Embedded wallet management
   - WalletConnect
   - Funding options
4. Console-style message log at bottom for debugging/feedback

### ViewModel Pattern
**HomeViewModel** manages home state as an `@ObservableObject`:
- Subscribes to `OFSDK.shared.embeddedStatePublisher` for wallet state changes
- Loads user data with `OFSDK.shared.getUser()`
- Provides `handleRecovery` closure for recovery configuration
- Manages logout flow with `OFSDK.shared.logOut()`
- Console message aggregation via `handleSetMessage()`

### Deep Link Handling
Deep links are handled via `.onOpenURL` modifier:
- OAuth redirects: `openfortios://login?access_token=...&refresh_token=...&player_id=...`
- Email verification: Stores email and state in UserDefaults, verified on next launch

## Dependencies
The project uses Swift Package Manager for dependencies (visible in xcodebuild output):
- **OpenfortSwift** - Main SDK from `https://github.com/openfort-xyz/swift-sdk.git`
- **Firebase iOS SDK** - Authentication and core services
- **GoogleSignIn-iOS** - Google authentication
- **Web3.swift** - Ethereum interactions
- **WalletConnect** (via websocket-kit) - WalletConnect protocol
- Various Apple Swift libraries (swift-crypto, swift-nio, etc.)

## Common Development Tasks

### Adding a New Authentication Provider
1. Add provider case to `OFAuthProvider` enum (if not already present)
2. Create button in LoginView's `socialButtonsView`
3. Implement handler function following the `startOAuth()` pattern
4. Update deep link handling if needed

### Adding New Wallet Features
1. Create a new View/Button component in appropriate subdirectory
2. Add to HomeView's feature panels section
3. Pass `handleSetMessage` closure for console logging
4. Use `OFSDK.shared` for SDK interactions

### Testing OAuth Flows
OAuth requires deep link redirection. Test using:
1. Run app in simulator
2. Trigger OAuth flow (opens Safari)
3. Complete authentication
4. Safari redirects to `openfortios://login` scheme
5. Simulator automatically returns to app with credentials

## Project Structure
- Target: `OpenfortAuthorization`
- Bundle ID: `com.openfort.OpenfortSample`
- Minimum iOS: 16.6
- Swift Version: 5.0
- Main App: `OpenfortAuthorizationApp.swift` (entry point using `@main`)
