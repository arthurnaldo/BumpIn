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
    @State private var showDisconnectConfirmation = false
    @State private var showUnfollowAlert = false
    @State private var showQRCode = false
    
    private var isOwnProfile: Bool {
        Auth.auth().currentUser?.uid == user.id
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let card = user.card {
                    ProfileHeaderView(card: card, user: user)
                    
                    if !isOwnProfile {
                        ConnectionButton(
                            isConnected: $isConnected,
                            hasRequestPending: $hasRequestPending,
                            hasIncomingRequest: $hasIncomingRequest,
                            isLoading: $isLoading,
                            showUnfollowAlert: $showUnfollowAlert,
                            user: user,
                            connectionService: connectionService,
                            checkStatus: checkStatus
                        )
                    }
                    
                    QRCodeButton(showQRCode: $showQRCode)
                    
                    BusinessCardSection(card: card)
                    
                    ContactInfoSection(card: card)
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
        .task {
            await checkStatus()
        }
        .transition(.move(edge: .trailing))
        .animation(.spring(
            response: CardDimensions.transitionDuration,
            dampingFraction: CardDimensions.springDamping
        ), value: user.id)
        .alert("Remove Connection?", isPresented: $showUnfollowAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                Task {
                    try? await connectionService.removeConnection(with: user.id)
                }
            }
        } message: {
            Text("Are you sure you want to remove @\(user.username) from your connections?")
        }
        .sheet(isPresented: $showQRCode) {
            NavigationView {
                ProfileQRCodeView(username: user.username)
                    .navigationTitle("Profile QR Code")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showQRCode = false
                            }
                        }
                    }
            }
        }
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

private struct ProfileHeaderView: View {
    let card: BusinessCard
    let user: User
    
    var body: some View {
        VStack(spacing: 0) {
            card.colorScheme.backgroundView(style: .gradient)
                .frame(height: 120)
                .overlay {
                    if let imageURL = card.profilePictureURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            defaultProfileImage
                        }
                        .frame(width: 86, height: 86)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(y: 43)
                    } else {
                        defaultProfileImage
                            .offset(y: 43)
                    }
                }
            
            VStack(spacing: 4) {
                Text(card.name)
                    .font(.title2)
                    .bold()
                
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(card.title)
                    .font(.headline)
                    .padding(.top, 4)
            }
            .padding(.top, 50)
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
}

private struct ConnectionButton: View {
    @Binding var isConnected: Bool
    @Binding var hasRequestPending: Bool
    @Binding var hasIncomingRequest: Bool
    @Binding var isLoading: Bool
    @Binding var showUnfollowAlert: Bool
    let user: User
    let connectionService: ConnectionService
    let checkStatus: () async -> Void
    
    var body: some View {
        Button(action: {
            print("👆 Button tapped! isConnected = \(isConnected), hasRequestPending = \(hasRequestPending)")
            if isConnected {
                showUnfollowAlert = true
            } else if hasRequestPending {
                handleCancelRequest()
            } else if hasIncomingRequest {
                handleAcceptRequest()
            } else {
                handleSendRequest()
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
                    .stroke(isConnected ? .gray : .clear, lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private func handleCancelRequest() {
        isLoading = true
        Task {
            do {
                try await connectionService.cancelConnectionRequest(to: user.id)
                hasRequestPending = false
                isConnected = false
                hasIncomingRequest = false
                print("✅ Successfully canceled request")
                await checkStatus()
            } catch {
                print("❌ Cancel request failed: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    private func handleAcceptRequest() {
        isLoading = true
        Task {
            do {
                if let request = try await connectionService.findPendingRequest(from: user.id) {
                    try await connectionService.handleConnectionRequest(request, accept: true)
                    isConnected = true
                    hasIncomingRequest = false
                    hasRequestPending = false
                    print("✅ Successfully accepted request")
                    await checkStatus()
                }
            } catch {
                print("❌ Accept request failed: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    private func handleSendRequest() {
        isLoading = true
        Task {
            do {
                try await connectionService.sendConnectionRequest(to: user)
                hasRequestPending = true
                isConnected = false
                hasIncomingRequest = false
                print("✅ Successfully sent request")
                await checkStatus()
            } catch {
                print("❌ Send request failed: \(error.localizedDescription)")
            }
            isLoading = false
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
}

private struct QRCodeButton: View {
    @Binding var showQRCode: Bool
    
    var body: some View {
        Button {
            showQRCode = true
        } label: {
            Image(systemName: "qrcode")
                .font(.system(size: 20))
                .foregroundColor(.gray)
        }
        .padding(.top, 8)
    }
}

private struct BusinessCardSection: View {
    let card: BusinessCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Business Card")
                    .font(.title3.bold())
                Spacer()
            }
            .padding(.horizontal, CardDimensions.horizontalPadding)
            
            BusinessCardPreview(card: card, showFull: false, selectedImage: nil)
                .frame(height: CardDimensions.previewHeight)
                .padding(.horizontal, CardDimensions.horizontalPadding)
        }
        .padding(.vertical)
    }
}

private struct ContactInfoSection: View {
    let card: BusinessCard
    
    var body: some View {
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
