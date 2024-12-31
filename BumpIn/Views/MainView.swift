import SwiftUI
import FirebaseAuth

struct MainView: View {
    @Binding var isAuthenticated: Bool
    @StateObject private var authService = AuthenticationService()
    @StateObject private var cardService = BusinessCardService()
    @StateObject private var userService = UserService()
    @StateObject private var connectionService = ConnectionService()
    @State private var showSignOutAlert = false
    @State private var showCreateCard = false
    @State private var showCardDetail = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isDarkMode = true
    @Namespace private var themeAnimation
    @State private var showQRCode = false
    
    private func fetchInitialData() async {
        guard let userId = authService.user?.uid else { return }
        
        do {
            // Fetch user data
            try await userService.fetchCurrentUser()
            
            // Ensure user has QR code
            try await userService.ensureUserHasQRCode()
            
            // Fetch card data
            if let card = try await cardService.fetchUserCard(userId: userId) {
                cardService.userCard = card
            }
            try await cardService.fetchContacts(userId: userId)
            
            // Start listeners
            cardService.startContactsListener(userId: userId)
        } catch {
            if (error as NSError).domain == "FIRFirestoreErrorDomain" {
                print("First-time user or document doesn't exist yet")
            } else {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                homeView
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Text("BumpIn")
                                .font(.system(size: 24, weight: .bold))
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            HStack {
                                if let currentUser = userService.currentUser {
                                    NotificationButton()
                                        .environmentObject(connectionService)
                                }
                            }
                        }
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationView {
                if let existingCard = cardService.userCard {
                    CreateCardView(cardService: cardService, existingCard: existingCard, selectedTab: $selectedTab)
                } else {
                    CreateCardView(cardService: cardService, selectedTab: $selectedTab)
                }
            }
            .tabItem {
                Label("My Card", systemImage: "person.crop.rectangle.fill")
            }
            .tag(1)
            
            ConnectionsView()
                .environmentObject(connectionService)
                .environmentObject(userService)
                .tabItem {
                    Label("Network", systemImage: "person.2.fill")
                }
                .tag(2)
            
            SettingsView()
                .environmentObject(userService)
                .environmentObject(authService)
                .environmentObject(cardService)
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(3)
        }
        .tint(Color(red: 0.1, green: 0.3, blue: 0.5))
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDarkMode)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showCardDetail) {
            if let card = cardService.userCard {
                CardDetailView(card: card, selectedImage: nil)
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                do {
                    try authService.signOut()
                    isAuthenticated = false
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .task {
            await fetchInitialData()
        }
        .onDisappear {
            cardService.stopContactsListener()
        }
        .onAppear {
            connectionService.startRequestsListener()
        }
        .onDisappear {
            connectionService.stopRequestsListener()
        }
        .sheet(isPresented: $showQRCode) {
            if let username = userService.currentUser?.username {
                NavigationView {
                    ProfileQRCodeView(username: username)
                        .navigationTitle("Your QR Code")
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
    }
    
    private var homeView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                if let card = cardService.userCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Card")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.horizontal, CardDimensions.horizontalPadding)
                        
                        BusinessCardPreview(card: card, showFull: false, selectedImage: nil)
                            .frame(height: CardDimensions.previewHeight)
                            .padding(.horizontal, CardDimensions.horizontalPadding)
                        
                        HStack(spacing: 16) {
                            // QR Code Button
                            Button {
                                showQRCode = true
                            } label: {
                                HStack {
                                    Image(systemName: "qrcode")
                                    Text("View QR Code")
                                }
                                .font(.system(.body, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(card.colorScheme.primary)
                                .cornerRadius(12)
                            }
                            
                            // Share Button
                            Button {
                                if let username = userService.currentUser?.username {
                                    let sharingService = CardSharingService(cardService: cardService)
                                    let profileLink = sharingService.generateProfileLink(for: username)
                                    let activityVC = UIActivityViewController(
                                        activityItems: [profileLink],
                                        applicationActivities: nil
                                    )
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let window = windowScene.windows.first,
                                       let rootVC = window.rootViewController {
                                        rootVC.present(activityVC, animated: true)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Profile")
                                }
                                .font(.system(.body, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(card.colorScheme.primary)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, CardDimensions.horizontalPadding)
                        .padding(.top, 8)
                    }
                } else {
                    Button(action: { selectedTab = 1 }) {
                        VStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40))
                            Text("Create Your Card")
                                .font(.headline)
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var cardsView: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(cardService.contacts) { card in
                        ContactBox(card: card)
                    }
                }
                .padding()
            }
            .navigationTitle("Contacts")
        }
    }
    
    struct NotificationButton: View {
        @EnvironmentObject var connectionService: ConnectionService
        @State private var showNotifications = false
        
        var body: some View {
            Button {
                showNotifications = true
            } label: {
                Image(systemName: "bell.fill")
                    .overlay(
                        Group {
                            if !connectionService.pendingRequests.isEmpty {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 6, y: -6)
                            }
                        }
                    )
            }
            .sheet(isPresented: $showNotifications) {
                NotificationView()
                    .environmentObject(connectionService)
            }
        }
    }
    
    private var defaultProfileImage: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
            )
    }
}

private struct ContactBox: View {
    let card: BusinessCard
    @State private var showCard = false
    
    var body: some View {
        Button(action: { showCard = true }) {
            VStack {
                Circle()
                    .fill(card.colorScheme.primary.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(card.name.prefix(1)))
                            .font(.title2)
                            .foregroundColor(card.colorScheme.primary)
                    )
                
                Text(card.name)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(card.title)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .sheet(isPresented: $showCard) {
            NavigationView {
                BusinessCardPreview(card: card, showFull: true, selectedImage: nil)
                    .navigationBarItems(trailing: Button("Done") {
                        showCard = false
                    })
            }
        }
    }
} 