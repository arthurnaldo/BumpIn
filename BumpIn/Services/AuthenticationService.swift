import SwiftUI
import FirebaseAuth

class AuthenticationService: ObservableObject {
    @Published var user: FirebaseAuth.User?
    @Published var errorMessage = ""
    
    init() {
        self.user = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
            }
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
} 