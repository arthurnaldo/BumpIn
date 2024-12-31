import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NetworkUserRow: View {
    let user: User
    let showConnectionStatus: Bool
    let isConnected: Bool
    @EnvironmentObject var connectionService: ConnectionService
    @State private var isLoading = false
    @State private var hasRequestPending = false
    @State private var hasIncomingRequest = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture or placeholder
            if let card = user.card, let imageURL = card.profilePictureURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    defaultProfileImage
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                defaultProfileImage
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text("@\(user.username)")
                    .font(.headline)
                if let card = user.card {
                    Text(card.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Connection status or action button
            if showConnectionStatus {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 90)
                } else if isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 90)
                } else if hasRequestPending {
                    Button(action: handleCancelRequest) {
                        Text("Requested")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 90, height: 30)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                } else if hasIncomingRequest {
                    Button(action: handleAcceptRequest) {
                        Text("Accept")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 90, height: 30)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                } else {
                    Button(action: handleSendRequest) {
                        Text("Connect")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 90, height: 30)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .contentShape(Rectangle()) // Makes the entire row tappable
        .task {
            await checkConnectionStatus()
        }
    }
    
    private var defaultProfileImage: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 50, height: 50)
            .overlay(
                Text(String(user.username.prefix(1).uppercased()))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
            )
    }
    
    private func checkConnectionStatus() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        do {
            // Check connection status
            let connection = try await Firestore.firestore()
                .collection("users")
                .document(currentUser.uid)
                .collection("connections")
                .document(user.id)
                .getDocument()
            
            // Check outgoing request
            let outgoingSnapshot = try await Firestore.firestore()
                .collection("users")
                .document(user.id)
                .collection("connectionRequests")
                .whereField("fromUserId", isEqualTo: currentUser.uid)
                .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
                .getDocuments()
            
            // Check incoming request
            let incomingSnapshot = try await Firestore.firestore()
                .collection("users")
                .document(currentUser.uid)
                .collection("connectionRequests")
                .whereField("fromUserId", isEqualTo: user.id)
                .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
                .getDocuments()
            
            await MainActor.run {
                hasRequestPending = !outgoingSnapshot.documents.isEmpty
                hasIncomingRequest = !incomingSnapshot.documents.isEmpty
            }
        } catch {
            print("Error checking connection status: \(error.localizedDescription)")
        }
    }
    
    private func handleSendRequest() {
        isLoading = true
        Task {
            do {
                try await connectionService.sendConnectionRequest(to: user.id)
                await checkConnectionStatus()
            } catch {
                print("Error sending request: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    private func handleCancelRequest() {
        isLoading = true
        Task {
            do {
                try await connectionService.cancelConnectionRequest(to: user.id)
                await checkConnectionStatus()
            } catch {
                print("Error canceling request: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    private func handleAcceptRequest() {
        isLoading = true
        Task {
            do {
                if let request = try await Firestore.firestore()
                    .collection("users")
                    .document(Auth.auth().currentUser?.uid ?? "")
                    .collection("connectionRequests")
                    .whereField("fromUserId", isEqualTo: user.id)
                    .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
                    .getDocuments()
                    .documents
                    .first {
                    let data = try JSONSerialization.data(withJSONObject: request.data())
                    let connectionRequest = try JSONDecoder().decode(ConnectionRequest.self, from: data)
                    try await connectionService.handleConnectionRequest(connectionRequest, accept: true)
                }
                await checkConnectionStatus()
            } catch {
                print("Error accepting request: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
} 