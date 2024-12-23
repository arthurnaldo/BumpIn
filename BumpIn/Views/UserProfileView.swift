import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserProfileView: View {
    let user: User
    @StateObject private var connectionService = ConnectionService()
    @State private var isConnected = false
    @State private var hasRequestPending = false
    @State private var hasIncomingRequest = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showFullCard = false
    
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
                        HStack(spacing: 12) {
                            // Connect/Following Button
                            Button(action: handleConnectionAction) {
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
                            .disabled(isLoading || hasRequestPending)
                            
                            // Message Button
                            Button(action: {
                                // Message functionality will be implemented later
                            }) {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("Message")
                                        .bold()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.clear)
                                .foregroundColor(.primary)
                                .cornerRadius(25)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                            }
                        }
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
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
        guard let currentUser = Auth.auth().currentUser else { return }
        
        do {
            async let connectionCheck = Firestore.firestore()
                .collection("users")
                .document(currentUser.uid)
                .collection("connections")
                .document(user.id)
                .getDocument()
            
            async let outgoingRequestCheck = connectionService.hasPendingRequest(for: user.id)
            async let incomingRequestCheck = connectionService.hasIncomingRequest(from: user.id)
            
            let (connection, hasPending, hasIncoming) = await (
                try connectionCheck,
                try outgoingRequestCheck,
                try incomingRequestCheck
            )
            
            isConnected = connection.exists
            hasRequestPending = hasPending
            hasIncomingRequest = hasIncoming
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
                } else if hasIncomingRequest {
                    if let request = try await connectionService.findPendingRequest(from: user.id) {
                        try await connectionService.handleConnectionRequest(request, accept: true)
                        isConnected = true
                        hasIncomingRequest = false
                    }
                } else {
                    try await connectionService.sendConnectionRequest(to: user)
                    hasRequestPending = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
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