import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserProfileView: View {
    let user: User
    @EnvironmentObject var connectionService: ConnectionService
    @State private var isConnected = false
    @State private var hasRequestPending = false
    @State private var hasIncomingRequest = false
    @State private var isLoading = false
    @State private var showFullCard = false
    @State private var showDisconnectConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile Header Card
                VStack(spacing: 0) {
                    // Background gradient from card if available
                    if let card = user.card {
                        card.colorScheme.backgroundView(style: .gradient)
                            .frame(height: 120)
                            .overlay {
                                // Profile Picture overlapping the gradient
                                if let imageURL = card.profilePictureURL {
                                    AsyncImage(url: URL(string: imageURL)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(.white, lineWidth: 3))
                                            .shadow(radius: 5)
                                    } placeholder: {
                                        defaultProfileImage
                                    }
                                    .offset(y: 50)
                                } else {
                                    defaultProfileImage
                                        .offset(y: 50)
                                }
                            }
                    } else {
                        LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 120)
                            .overlay {
                                defaultProfileImage
                                    .offset(y: 50)
                            }
                    }
                    
                    // User Info Section
                    VStack(spacing: 8) {
                        Text("@\(user.username)")
                            .font(.title2.bold())
                            .padding(.top, 60)
                        
                        if let card = user.card {
                            Text(card.title)
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            if !card.company.isEmpty {
                                Text(card.company)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !card.aboutMe.isEmpty {
                                Text(card.aboutMe)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .padding(.top, 4)
                            }
                        }
                        
                        // Action Buttons
                        Button(action: {
                            print("👆 Button tapped! isConnected = \(isConnected), hasRequestPending = \(hasRequestPending)")
                            if isConnected {
                                // Handle disconnect
                                isLoading = true
                                Task {
                                    do {
                                        try await connectionService.removeConnection(with: user.id)
                                        isConnected = false
                                        hasRequestPending = false
                                        hasIncomingRequest = false
                                        print("✅ Successfully disconnected")
                                        await checkStatus()  // Refresh status after disconnect
                                    } catch {
                                        print("❌ Disconnect failed: \(error.localizedDescription)")
                                    }
                                    isLoading = false
                                }
                            } else if hasRequestPending {
                                // Handle canceling request
                                isLoading = true
                                Task {
                                    do {
                                        try await connectionService.cancelConnectionRequest(to: user.id)
                                        hasRequestPending = false
                                        isConnected = false
                                        hasIncomingRequest = false
                                        print("✅ Successfully canceled request")
                                        await checkStatus()  // Refresh status after canceling
                                    } catch {
                                        print("❌ Cancel request failed: \(error.localizedDescription)")
                                    }
                                    isLoading = false
                                }
                            } else if hasIncomingRequest {
                                // Handle accepting request
                                isLoading = true
                                Task {
                                    do {
                                        if let request = try await connectionService.findPendingRequest(from: user.id) {
                                            try await connectionService.handleConnectionRequest(request, accept: true)
                                            isConnected = true
                                            hasIncomingRequest = false
                                            hasRequestPending = false
                                            print("✅ Successfully accepted request")
                                            await checkStatus()  // Refresh status after accepting
                                        }
                                    } catch {
                                        print("❌ Accept request failed: \(error.localizedDescription)")
                                    }
                                    isLoading = false
                                }
                            } else {
                                // Handle sending new request
                                isLoading = true
                                Task {
                                    do {
                                        try await connectionService.sendConnectionRequest(to: user)
                                        hasRequestPending = true
                                        isConnected = false
                                        hasIncomingRequest = false
                                        print("✅ Successfully sent request")
                                        await checkStatus()  // Refresh status after sending
                                    } catch {
                                        print("❌ Send request failed: \(error.localizedDescription)")
                                    }
                                    isLoading = false
                                }
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: connectionIcon)
                                    Text(buttonTitle)
                                        .bold()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(buttonBackground)
                            .foregroundColor(buttonTextColor)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(buttonBackground == .clear ? Color.gray : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                    .padding(.bottom, 20)
                }
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 10)
                .padding()
                
                // Business Card Section
                if let card = user.card {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Business Card")
                                .font(.title3.bold())
                            
                            Spacer()
                            
                            Button {
                                showFullCard = true
                            } label: {
                                Label("View Full", systemImage: "arrow.up.forward.square")
                                    .font(.subheadline)
                            }
                        }
                        .padding(.horizontal)
                        
                        BusinessCardPreview(card: card, showFull: false, selectedImage: nil)
                            .frame(height: 200)
                            .padding(.horizontal)
                            .onTapGesture {
                                showFullCard = true
                            }
                    }
                    .padding(.vertical)
                }
                
                // Contact Info Section
                if let card = user.card {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact Information")
                            .font(.title3.bold())
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            if !card.email.isEmpty {
                                ContactInfoRow(icon: "envelope.fill", title: "Email", value: card.email)
                            }
                            if !card.phone.isEmpty {
                                ContactInfoRow(icon: "phone.fill", title: "Phone", value: card.phone)
                            }
                            if !card.linkedin.isEmpty {
                                ContactInfoRow(icon: "link", title: "LinkedIn", value: card.linkedin)
                            }
                            if !card.website.isEmpty {
                                ContactInfoRow(icon: "globe", title: "Website", value: card.website)
                            }
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Disconnect from @\(user.username)?",
            isPresented: $showDisconnectConfirmation,
            titleVisibility: .visible
        ) {
            Button("Disconnect", role: .destructive) {
                isLoading = true
                Task {
                    do {
                        try await connectionService.removeConnection(with: user.id)
                        isConnected = false
                        showDisconnectConfirmation = false
                        await checkStatus()
                    } catch {
                        print("Connection action failed: \(error.localizedDescription)")
                    }
                    isLoading = false
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You will need to send a new connection request to reconnect.")
        }
        .sheet(isPresented: $showFullCard) {
            if let card = user.card {
                CardDetailView(card: card, selectedImage: nil)
            }
        }
        .task {
            await checkStatus()
        }
    }
    
    private var connectionIcon: String {
        if isConnected {
            return "checkmark.circle.fill"
        } else if hasIncomingRequest {
            return "person.crop.circle.badge.plus"
        } else if hasRequestPending {
            return "clock.fill"
        } else {
            return "person.badge.plus"
        }
    }
    
    private var defaultProfileImage: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 86, height: 86)
            .overlay(
                Text(String(user.username.prefix(1).uppercased()))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.gray)
            )
    }
    
    private var buttonTitle: String {
        if isConnected {
            return "Connected"
        } else if hasIncomingRequest {
            return "Accept"
        } else if hasRequestPending {
            return "Requested"
        } else {
            return "Connect"
        }
    }
    
    private var buttonBackground: Color {
        if isConnected {
            return .clear
        } else if hasIncomingRequest {
            return .blue
        } else if hasRequestPending {
            return .gray
        } else {
            return .blue
        }
    }
    
    private var buttonTextColor: Color {
        isConnected ? .primary : .white
    }
    
    private func checkStatus() async {
        guard let currentUser = Auth.auth().currentUser else {
            print("No current user")
            return 
        }
        
        print("🔍 Checking connection status for user: \(user.id)")
        
        do {
            // Check connection status
            let connection = try await Firestore.firestore()
                .collection("users")
                .document(currentUser.uid)
                .collection("connections")
                .document(user.id)
                .getDocument()
            
            // Check outgoing request (in their connectionRequests)
            let outgoingSnapshot = try await Firestore.firestore()
                .collection("users")
                .document(user.id)
                .collection("connectionRequests")
                .whereField("fromUserId", isEqualTo: currentUser.uid)
                .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
                .getDocuments()
            
            // Check incoming request (in our connectionRequests)
            let incomingSnapshot = try await Firestore.firestore()
                .collection("users")
                .document(currentUser.uid)
                .collection("connectionRequests")
                .whereField("fromUserId", isEqualTo: user.id)
                .whereField("status", isEqualTo: ConnectionRequest.RequestStatus.pending.rawValue)
                .getDocuments()
            
            await MainActor.run {
                isConnected = connection.exists
                hasRequestPending = !outgoingSnapshot.documents.isEmpty
                hasIncomingRequest = !incomingSnapshot.documents.isEmpty
                
                print("""
                ✅ Status check complete:
                - isConnected: \(isConnected)
                - hasRequestPending: \(hasRequestPending) (we sent request)
                - hasIncomingRequest: \(hasIncomingRequest) (they sent request)
                - Documents found: outgoing=\(outgoingSnapshot.documents.count), incoming=\(incomingSnapshot.documents.count)
                """)
            }
        } catch {
            print("❌ Status check failed: \(error.localizedDescription)")
        }
    }
}

struct ContactInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            
            Spacer()
        }
    }
} 