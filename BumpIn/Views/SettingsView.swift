import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var userService: UserService
    @State private var showSignOutAlert = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    if let user = userService.currentUser {
                        HStack {
                            Text("Username")
                            Spacer()
                            Text("@\(user.username)")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let email = Auth.auth().currentUser?.email {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    do {
                        try authService.signOut()
                    } catch {
                        showError = true
                        errorMessage = error.localizedDescription
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
        .onAppear {
            if let currentUser = userService.currentUser {
                isLoading = true
                isLoading = false
            }
        }
    }
} 