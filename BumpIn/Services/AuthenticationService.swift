import SwiftUI
import FirebaseAuth
import Foundation

class AuthenticationService: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var errorMessage = ""
    
    init() {
        print("AuthenticationService: Initializing")
        self.user = Auth.auth().currentUser
        print("AuthenticationService: Initial user - \(self.user?.uid ?? "nil")")
        
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            print("AuthenticationService: Auth state changed - User: \(user?.uid ?? "nil")")
            DispatchQueue.main.async {
                self?.user = user
            }
        }
    }
    
    func signOut() throws {
        print("AuthenticationService: Signing out")
        Task {
            await CacheManager.shared.clearCache()
        }
        try Auth.auth().signOut()
    }
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.userNotFound
        }
        
        try await user.delete()
        self.user = nil
    }
} 