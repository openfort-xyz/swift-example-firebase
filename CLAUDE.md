# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI example application demonstrating the Openfort Swift SDK integration with Firebase Authentication. It showcases embedded wallet functionality, authentication flows (email/password, OAuth, guest, Apple Sign-In), wallet management, message signing, and account recovery mechanisms.

## Build & Run Commands

### Build the Project
```bash
xcodebuild -project OpenfortAuthorization/OpenfortFirebaseAuthorization.xcodeproj -scheme OpenfortAuthorization -configuration Debug build
```

### Run Tests
```bash
# Run all tests
xcodebuild test -project OpenfortAuthorization/OpenfortFirebaseAuthorization.xcodeproj -scheme OpenfortAuthorization -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test target
xcodebuild test -project OpenfortAuthorization/OpenfortFirebaseAuthorization.xcodeproj -scheme OpenfortAuthorization -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:OpenfortAuthorizationTests

# Run UI tests
xcodebuild test -project OpenfortAuthorization/OpenfortFirebaseAuthorization.xcodeproj -scheme OpenfortAuthorization -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:OpenfortAuthorizationUITests
```

### Clean Build
```bash
xcodebuild clean -project OpenfortAuthorization/OpenfortFirebaseAuthorization.xcodeproj -scheme OpenfortAuthorization
```

## Configuration

### OFConfig.plist
The app requires configuration via `OpenfortAuthorization/OpenfortAuthorization/OFConfig.plist`:
- `openfortPublishableKey` - Openfort publishable key (required)
- `shieldPublishableKey` - Shield publishable key (required)
- `backendUrl` - Backend API URL (optional)
- `shieldUrl` - Shield service URL (optional)
- `debug` - Enable debug logging (boolean, optional)

### GoogleService-Info.plist
Firebase configuration required for Firebase Authentication integration at `OpenfortAuthorization/OpenfortAuthorization/GoogleService-Info.plist`. Download from the Firebase Console for your project.

## Architecture

### SDK Initialization Flow
1. **AppDelegate.swift** - Firebase and Openfort SDK initialization happens in `application(_:didFinishLaunchingWithOptions:)`
   - Firebase is configured first with `FirebaseApp.configure()`
   - Openfort SDK is set up with third-party Firebase auth support using `OFSDK.setupSDK(thirdParty: .firebase)`
   - The SDK receives a closure that dynamically fetches Firebase ID tokens via `Auth.auth().currentUser?.getIDToken()` when needed

### Authentication Flow
1. **LoginView** - Entry point, handles multiple auth methods:
   - Email/password authentication via Firebase Auth
   - Apple Sign-In using `SignInWithAppleButton` and ASAuthorization (with optional biometric gating)
   - Guest sign-up via anonymous Firebase Auth (`Auth.auth().signInAnonymously()`)
   - Session restoration via `Auth.auth().currentUser` check on app launch

2. **RegisterView** - User registration with:
   - First name, last name, email, password fields
   - Password validation (8+ chars, uppercase, lowercase, special character)
   - Email verification via `user.sendEmailVerification()`
   - Terms of service links

3. **Firebase Integration** - Firebase Auth is the authentication backend:
   - User authenticates with Firebase first
   - Firebase ID token is automatically provided to Openfort SDK via the closure set in AppDelegate
   - Openfort SDK uses the token for subsequent API calls
   - Logout calls both `OFSDK.shared.logOut()` and `Auth.auth().signOut()`

4. **Password Reset** - Two-step flow:
   - `ForgotPasswordView` sends reset email via `Auth.auth().sendPasswordReset(withEmail:)`
   - `ResetPasswordView` completes reset via `Auth.auth().confirmPasswordReset(withCode:newPassword:)`

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
   - Configuration includes `chainId: 80002` (Polygon Amoy testnet) and recovery parameters

2. **Automatic Recovery** - Uses server-side encryption session:
   - Fetches encryption session from backend API (`getEncryptionSession()` async)
   - Session string passed to `OFSDK.shared.configure()` with `recoveryMethod: .automatic`
   - Backend endpoint: `https://create-next-app.openfort.io/api/protected-create-encryption-session`

### Component Organization
- **AccountActions/** - Transaction and blockchain interaction buttons (EIP-1193 and backend-based minting)
- **SessionKey/** - Session key creation and management (backend and EIP-1193 modes)
- **Signatures/** - Message signing (`SignMessageButton`) and EIP-712 typed data signing (`SignTypedDataButton`)
- **OAuth/** - Social login linking (`LinkOAuthButton`) and linked accounts display (`LinkedSocialsPanelView`)
- **Export/** - Private key export (`ExportPrivateKeyButton`) and recovery method management (`EmbeddedWalletPanelView`)
- **WalletConnect/** - WalletConnect protocol pairing and session management
- **Funding/** - Wallet funding flows with on-ramp providers (Coinbase, Moonpay) and manual transfer
- **User/** - User data display (`GetUserButton`)
- **WalletRecovery/** - Recovery method switching between password and automatic
- **Utils/** - Shared utilities:
  - `SIWE.swift` - Sign-In With Ethereum message generation (EIP-4361)
  - `EncriptionSession.swift` - Backend API call for encryption sessions (async/await)
  - `AppleAuthManager.swift` - Apple Sign-In and biometric authentication helpers
  - `RedirectManager.swift` - Deep link URI generation from bundle identifier

### HomeView Architecture
**HomeView** serves as the main authenticated interface with different states:
1. Shows `AccountRecoveryView` when `state == .embeddedSignerNotConfigured`
2. Displays loading UI with spinner when `state == .creatingAccount`
3. Shows feature panels when `state == .ready`:
   - Signatures panel (message and typed data signing)
   - Linked socials panel (OAuth provider linking)
   - Embedded wallet panel (private key export, recovery method changes)
   - Account actions, WalletConnect, and Funding panels exist but are currently disabled
4. Console-style monospaced message log at bottom for debugging/feedback

### ViewModel Pattern
**HomeViewModel** manages home state as an `@ObservableObject`:
- Subscribes to `OFSDK.shared.embeddedStatePublisher` for wallet state changes
- Loads user data with `OFSDK.shared.getUser()` (returns `OFUser?`)
- Provides `handleRecovery` closure for recovery configuration with `OFEmbeddedAccountConfigureParams`
- Manages logout flow with `OFSDK.shared.logOut()` followed by `Auth.auth().signOut()`
- Console message aggregation via `handleSetMessage()`

### WalletListView Architecture
**WalletListView** provides multi-wallet management:
- `WalletWithChainIds` model consolidates wallets by address across chains
- Filters for `SMART_ACCOUNT` type only
- Auto-creates first wallet if list is empty on initial load
- Supports wallet creation with automatic recovery and wallet recovery by ID
- Uses `OpenfortEmbeddedService` protocol for pluggable SDK access

### Deep Link Handling
Deep links use a scheme derived from the bundle identifier via `RedirectManager`:
- Scheme: last component of bundle ID lowercased (e.g., `noncustodial` from `com.openfort.noncustodial`)
- OAuth redirects: `{scheme}://login?access_token=...&refresh_token=...&player_id=...`
- Handled via `.onOpenURL` modifier on the root view

## Dependencies
The project uses Swift Package Manager:
- **OpenfortSwift** (main branch) - Openfort SDK from `https://github.com/openfort-xyz/swift-sdk.git`
- **Firebase iOS SDK** (12.4.0) - FirebaseCore and FirebaseAuth
- **Web3.swift** (0.8.8) - Ethereum interactions, contract ABI, and PromiseKit integration

Notable transitive dependencies: swift-crypto, swift-nio, CryptoSwift, BigInt, secp256k1.swift, PromiseKit.

## Common Development Tasks

### Adding a New Authentication Provider
1. Add sign-in logic in `LoginView` following existing patterns (e.g., Apple Sign-In flow)
2. Authenticate with Firebase first, then let the SDK token closure handle Openfort auth
3. Update deep link handling in `.onOpenURL` if OAuth-based

### Adding New Wallet Features
1. Create a new View/Button component in the appropriate subdirectory
2. Add to HomeView's feature panels section (inside the `.ready` state block)
3. Pass `handleSetMessage` closure for console logging
4. Use `OFSDK.shared` for SDK interactions

### Testing OAuth Flows
OAuth requires deep link redirection. Test using:
1. Run app in simulator
2. Trigger OAuth flow (opens Safari)
3. Complete authentication in browser
4. Browser redirects back to app via URL scheme
5. App receives credentials and stores them

## Project Structure
- Xcode Project: `OpenfortFirebaseAuthorization.xcodeproj`
- Scheme: `OpenfortAuthorization`
- Bundle ID: `com.openfort.noncustodial`
- Minimum iOS: 16.6
- Swift Version: 5.0
- Main App: `OpenfortAuthorizationApp.swift` (entry point using `@main`)
- Entitlements: Apple Sign-In, App Sandbox
