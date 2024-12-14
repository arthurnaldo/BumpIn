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
    @State private var isLoading = true
    
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
    }
}

#Preview {
    ContentView()
}
