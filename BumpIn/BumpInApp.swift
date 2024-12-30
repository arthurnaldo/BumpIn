//
//  BumpInApp.swift
//  BumpIn
//
//  Created by Arthur on 12/14/24.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct BumpInApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var cardService = BusinessCardService()
    @StateObject private var userService = UserService()
    @State private var foundUser: User?
    @State private var showUserProfile = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cardService)
                .environmentObject(userService)
                .onOpenURL { url in
                    print("\n🔗 Processing URL: \(url.absoluteString)")
                    
                    // Parse the URL properly
                    let urlString = url.absoluteString
                    guard let schemeRange = urlString.range(of: "bumpin://") else {
                        print("❌ Invalid URL: missing scheme")
                        return
                    }
                    
                    // Get the path after the scheme
                    let path = urlString[schemeRange.upperBound...]
                    let components = path.split(separator: "/")
                    print("📝 URL components after scheme: \(components)")
                    
                    guard !components.isEmpty else {
                        print("❌ Invalid URL: no components after scheme")
                        return
                    }
                    
                    let type = String(components[0])
                    print("🏷️ URL type: \(type)")
                    
                    if type == "profile", components.count > 1 {
                        let username = String(components[1])
                        print("\n👤 Processing profile link for username: '\(username)'")
                        Task {
                            do {
                                print("🔍 Starting user search...")
                                try await userService.searchUsers(query: username)
                                print("📊 Search returned \(userService.searchResults.count) results")
                                
                                if let matchedUser = userService.searchResults.first {
                                    print("✅ Found matching user: \(matchedUser.username)")
                                    await MainActor.run {
                                        foundUser = matchedUser
                                        showUserProfile = true
                                    }
                                } else {
                                    print("❌ No user found with username: '\(username)'")
                                    errorMessage = "No user found with username '@\(username)'"
                                    showError = true
                                }
                            } catch {
                                print("❌ Error searching for user: \(error.localizedDescription)")
                                errorMessage = "Failed to search for user: \(error.localizedDescription)"
                                showError = true
                            }
                        }
                    } else {
                        print("❌ Unknown URL type: \(type)")
                        errorMessage = "Invalid link format"
                        showError = true
                    }
                }
                .sheet(isPresented: $showUserProfile) {
                    if let user = foundUser {
                        NavigationView {
                            UserProfileView(user: user)
                        }
                    }
                }
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage ?? "Unknown error")
                }
        }
    }
}
