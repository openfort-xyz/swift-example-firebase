# Quickstart

This is a companion project to the [Openfort Swift Quickstart guide](https://github.com/openfort-xyz/swift-sdk).  
It demonstrates the basic use of the [Openfort Swift SDK](https://github.com/openfort-xyz/swift-sdk) in a SwiftUI application.

## Overview

This quickstart example shows how to:

- Configure the Openfort Swift SDK in a SwiftUI application
- Set up and use the `OFConfig.plist` file
- Implement sign-in and sign-up flows
- Handle authenticated and unauthenticated states
- Display the user profile and wallet information
- Demonstrate account linking, embedded wallets, and logout flows

## Setup

### 1. Create an Openfort Application

1. Sign up at [openfort.io](https://openfort.io)
2. Create a new project in your Openfort Dashboard
3. Copy your **Publishable Key** and **Shield Keys** from the Developers section

### 2. Configure the Example

Open OFConfig.plist and configure the following keys:
   - `backendURL` – Your backend API base URL (optional)
   - `iframeURL` – URL of your iframe environment (optional)
   - `openfortPublishableKey` – Your Openfort publishable key
   - `shieldPublishableKey` – Your Shield publishable key
   - `shieldEncryptionKey` – Your Shield encryption key
   - `shieldURL` – Shield service URL (optional)

### 3. Run the App

1. Choose your target device/simulator
2. Build and run the project (⌘+R)
