import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserProfileView: View {
    let user: User
    @StateObject private var connectionService = ConnectionService()
    @State private var isConnected = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(String(user.username.prefix(1).uppercased()))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.gray)
                        )
                    
                    Text("@\(user.username)")
                        .font(.title2)
                        .bold()
                    
                    if let card = user.card {
                        Text(card.title)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top)
                
                // Connection Button
                Button(action: {
                    handleConnectionAction()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isConnected ? "Disconnect" : "Connect")
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isConnected ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .disabled(isLoading)
                
                if let card = user.card {
                    BusinessCardPreview(card: card, showFull: true, selectedImage: nil)
                        .padding()
                }
            }
        }
        .navigationTitle("Profile")
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await checkConnectionStatus()
        }
    }
    
    private func checkConnectionStatus() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        do {
            let doc = try await Firestore.firestore()
                .collection("users")
                .document(currentUser.uid)
                .collection("connections")
                .document(user.id)
                .getDocument()
            
            isConnected = doc.exists
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleConnectionAction() {
        isLoading = true
        Task {
            do {
                if isConnected {
                    try await connectionService.removeConnection(with: user.id)
                    isConnected = false
                } else {
                    try await connectionService.sendConnectionRequest(to: user)
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
} 