import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserProfileView: View {
    let user: User
    @EnvironmentObject var connectionService: ConnectionService
    @State private var isConnected = false
    @State private var hasRequestPending = false
    @State private var hasIncomingRequest = false
    @State private var isLoading = true
    @State private var showDisconnectConfirmation = false
    @State private var showUnfollowAlert = false
    @State private var showQRCode = false
    @StateObject private var storageService = StorageService()
    @State private var preloadedImage: UIImage?
    
    private var isOwnProfile: Bool {
        Auth.auth().currentUser?.uid == user.id
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        if let card = user.card {
                            ProfileHeaderView(card: card, user: user, preloadedImage: preloadedImage)
                            
                            if !isOwnProfile {
                                ConnectionButton(
                                    isConnected: $isConnected,
                                    hasRequestPending: $hasRequestPending,
                                    hasIncomingRequest: $hasIncomingRequest,
                                    showUnfollowAlert: $showUnfollowAlert,
                                    user: user,
                                    connectionService: connectionService,
                                    checkStatus: checkStatus
                                )
                            }
                            
                            QRCodeButton(showQRCode: $showQRCode, username: user.username)
                            
                            BusinessCardSection(card: card, preloadedImage: preloadedImage)
                            
                            ContactInfoSection(card: card)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showUnfollowAlert) {
            ZStack {
                // Background blur
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                // Content
                VStack(spacing: 0) {
                    // Header with icon
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.badge.minus")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.red)
                            )
                        
                        VStack(spacing: 8) {
                            Text("Remove Connection")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Are you sure you want to remove")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            Text("@\(user.username)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                            Text("from your connections?")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                    
                    // Divider
                    Divider()
                        .padding(.horizontal, 24)
                    
                    // Warning message
                    Text("You'll need to send a new request to reconnect.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    
                    // Divider
                    Divider()
                        .padding(.horizontal, 24)
                    
                    // Buttons
                    VStack(spacing: 12) {
                        // Remove button
                        Button {
                            Task {
                                do {
                                    try await connectionService.removeConnection(with: user.id)
                                    await MainActor.run {
                                        isConnected = false
                                        hasRequestPending = false
                                        hasIncomingRequest = false
                                        showUnfollowAlert = false
                                    }
                                } catch {
                                    print("Failed to remove connection: \(error.localizedDescription)")
                                }
                            }
                        } label: {
                            Text("Remove Connection")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                        
                        // Cancel button
                        Button {
                            showUnfollowAlert = false
                        } label: {
                            Text("Keep Connection")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(24)
                }
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(24)
                .padding(.horizontal, 20)
            }
            .interactiveDismissDisabled()
        }
        .confirmationDialog(
            "Disconnect from @\(user.username)?",
            isPresented: $showDisconnectConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                Task {
                    do {
                        try await connectionService.removeConnection(with: user.id)
                        await MainActor.run {
                            isConnected = false
                            hasRequestPending = false
                            hasIncomingRequest = false
                            showDisconnectConfirmation = false
                        }
                    } catch {
                        print("Connection action failed: \(error.localizedDescription)")
                    }
                }
            }
        } message: {
            Text("You will need to send a new connection request to reconnect.")
        }
        .task {
            await loadData()
        }
        .transition(.move(edge: .trailing))
        .animation(.spring(
            response: CardDimensions.transitionDuration,
            dampingFraction: CardDimensions.springDamping
        ), value: user.id)
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
    
    private func loadData() async {
        // Load profile image
        if let card = user.card, let imageURL = card.profilePictureURL {
            if let image = try? await storageService.loadProfileImage(from: imageURL) {
                await MainActor.run {
                    preloadedImage = image
                }
            }
        }
        
        // Check connection status
        await checkStatus()
        
        await MainActor.run {
            isLoading = false
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
                - Connected: \(isConnected)
                - Has Pending Request: \(hasRequestPending)
                - Has Incoming Request: \(hasIncomingRequest)
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
    let preloadedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 0) {
            card.colorScheme.backgroundView(style: .gradient)
                .frame(height: 120)
                .overlay {
                    if let image = preloadedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
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
    @State private var isButtonLoading = false
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
            HStack(spacing: 6) {
                if isButtonLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: connectionIcon)
                        .font(.system(size: 14))
                    Text(buttonTitle)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(buttonBackground)
            .foregroundColor(buttonTextColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isConnected ? Color(.systemGray3) : .clear, lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private func handleCancelRequest() {
        isButtonLoading = true
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
            isButtonLoading = false
        }
    }
    
    private func handleAcceptRequest() {
        isButtonLoading = true
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
                await checkStatus()
            } catch {
                print("❌ Accept request failed: \(error.localizedDescription)")
            }
            isButtonLoading = false
        }
    }
    
    private func handleSendRequest() {
        isButtonLoading = true
        Task {
            do {
                try await connectionService.sendConnectionRequest(to: user.id)
                hasRequestPending = true
                print("✅ Successfully sent request")
                await checkStatus()
            } catch {
                print("❌ Send request failed: \(error.localizedDescription)")
            }
            isButtonLoading = false
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
            return Color(.systemGray5)
        } else {
            return .blue
        }
    }
    
    private var buttonTextColor: Color {
        if isConnected || hasRequestPending {
            return .primary
        } else {
            return .white
        }
    }
}

private struct QRCodeButton: View {
    @Binding var showQRCode: Bool
    let username: String
    @State private var showShareSheet = false
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                showQRCode = true
            } label: {
                HStack {
                    Image(systemName: "qrcode")
                    Text("View QR Code")
                }
                .font(.system(size: 16))
                .foregroundColor(.gray)
            }
            
            Button {
                showShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Profile")
                }
                .font(.system(size: 16))
                .foregroundColor(.gray)
            }
        }
        .padding(.top, 8)
        .sheet(isPresented: $showShareSheet) {
            let sharingService = CardSharingService(cardService: BusinessCardService())
            let profileLink = sharingService.generateProfileLink(for: username)
            ShareSheet(activityItems: [profileLink])
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct BusinessCardSection: View {
    let card: BusinessCard
    let preloadedImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Business Card")
                    .font(.title3.bold())
                Spacer()
            }
            .padding(.horizontal, CardDimensions.horizontalPadding)
            
            BusinessCardPreview(card: card, showFull: false, selectedImage: preloadedImage)
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
