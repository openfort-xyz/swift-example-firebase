//
//  AppDelegate.swift
//  OpenfortAuthorization
//
//  Created by Pavlo Hurkovskyi on 2025-07-24.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import OpenfortSwift

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase first
        FirebaseApp.configure()

        // Initialize Openfort SDK with Firebase third-party auth support
        // The getAccessToken closure will be called dynamically when needed
        
        do {
            try OFSDK.setupSDK(thirdParty: .firebase) {
                // This closure is called when the SDK needs a Firebase ID token
                // It will only succeed if a user is currently signed in to Firebase
                try await Auth.auth().currentUser?.getIDToken()
            }
        } catch {
            print("Unable to setup Openfort SDK: \(error.localizedDescription)")
        }

        return true
    }
}
