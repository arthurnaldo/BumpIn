//
//  ContentView.swift
//  BumpIn
//
//  Created by Arthur on 12/14/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @EnvironmentObject var cardService: BusinessCardService
    @State private var isLoading = true
    @State private var foundCard: BusinessCard?
    @State private var showFoundCard = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
                    .scaleEffect(1.5)
            } else if let user = authService.user {
                MainView(isAuthenticated: .constant(true))
                    .environmentObject(authService)
            } else {
                LoginView(isAuthenticated: .constant(false))
                    .environmentObject(authService)
            }
        }
        .onAppear {
            // Check auth state immediately
            isLoading = false
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

#Preview {
    ContentView()
}
