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
    @State private var foundCard: BusinessCard?
    @State private var showFoundCard = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cardService)
                .onOpenURL { url in
                    print("🔗 Received URL: \(url.absoluteString)")
                    if let cardId = url.absoluteString.components(separatedBy: "/").last {
                        Task {
                            do {
                                if let card = try? await cardService.fetchCardById(cardId) {
                                    print("✅ Found card: \(card.name)")
                                    await MainActor.run {
                                        foundCard = card
                                        showFoundCard = true
                                    }
                                    try await cardService.addCard(card)
                                    print("✅ Added to contacts: \(card.name)")
                                }
                            } catch {
                                print("❌ Error: \(error.localizedDescription)")
                                // Show error alert here
                            }
                        }
                    }
                }
                .alert("Add Contact?", isPresented: $showFoundCard) {
                    Button("Add") {
                        if let card = foundCard {
                            Task {
                                try? await cardService.addCard(card)
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    if let card = foundCard {
                        Text("Would you like to add \(card.name) to your contacts?")
                    }
                }
        }
    }
}
