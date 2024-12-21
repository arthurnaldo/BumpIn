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
    @State private var errorMessage: String?
    @State private var showError = false
    
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
                                }
                            } catch {
                                print("❌ Error: \(error.localizedDescription)")
                                await MainActor.run {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }
                    }
                }
                .alert("Add Contact?", isPresented: $showFoundCard) {
                    Button("Add") {
                        if let card = foundCard {
                            Task {
                                do {
                                    try await cardService.addCard(card)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    if let card = foundCard {
                        Text("Would you like to add \(card.name) to your contacts?")
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
