import SwiftUI
import FirebaseAuth

struct MainView: View {
    @Binding var isAuthenticated: Bool
    @StateObject private var authService = AuthenticationService()
    @StateObject private var cardService = BusinessCardService()
    @StateObject private var userService = UserService()
    @StateObject private var connectionService = ConnectionService()
    @StateObject private var storageService = StorageService()
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
    @State private var isLoading = true
    @State private var preloadedImage: UIImage?
    
    private func fetchInitialData() async {
        isLoading = true
        guard let userId = authService.user?.uid else { return }
        
        do {
            // Fetch user data
            try await userService.fetchCurrentUser()
            
            // Ensure user has QR code
            try await userService.ensureUserHasQRCode()
            
            // Fetch card data
            if let card = try await cardService.fetchUserCard(userId: userId) {
                cardService.userCard = card
                
                // Preload profile image if exists
                if let imageURL = card.profilePictureURL {
                    if let image = try? await storageService.loadProfileImage(from: imageURL) {
                        await MainActor.run {
                            preloadedImage = image
                        }
                    }
                }
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
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                homeView
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            HStack(spacing: 0) {
                                Text("Bump")
                                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                Text("In")
                                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.leading, -3)
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            HStack {
                                if userService.currentUser != nil {
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
                Label("My Card", systemImage: "rectangle.stack.fill")
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
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.white)
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
        .task {
            if let card = cardService.userCard, let imageURL = card.profilePictureURL {
                if let image = try? await storageService.loadProfileImage(from: imageURL) {
                    await MainActor.run {
                        preloadedImage = image
                    }
                }
            }
        }
        .onChange(of: cardService.userCard?.profilePictureURL) { _, newURL in
            if let imageURL = newURL {
                Task {
                    if let image = try? await storageService.loadProfileImage(from: imageURL) {
                        await MainActor.run {
                            preloadedImage = image
                        }
                    }
                }
            }
        }
    }
    
    private var homeView: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    if let card = cardService.userCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Card")
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal, CardDimensions.horizontalPadding)
                            
                            BusinessCardPreview(card: card, showFull: false, selectedImage: preloadedImage)
                                .frame(height: CardDimensions.previewHeight)
                                .padding(.horizontal, CardDimensions.horizontalPadding)
                        }
                    } else {
                        Button(action: { selectedTab = 1 }) {
                            VStack(spacing: 16) {
                                Image(systemName: "person.crop.rectangle.badge.plus")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                
                                Text("Create Your Digital Card")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Start networking with a professional digital business card")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: { selectedTab = 1 }) {
                                    Text("Get Started")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(red: 0.2, green: 0.4, blue: 0.8))
                                        .cornerRadius(12)
                                }
                                .padding(.top, 8)
                            }
                            .padding(24)
                            .background(Color(white: 0.15))
                            .cornerRadius(20)
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
    }
    
    struct ActionButton: View {
        let icon: String
        let title: String
        let subtitle: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(alignment: .top, spacing: 16) {
                    // Icon container with fixed size
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                        .frame(width: 24, height: 24)
                        .padding(.top, 2)
                    
                    // Text container
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .padding(.horizontal, 20)
                .background(Color(white: 0.15))
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .cornerRadius(0)
            }
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
                ZStack {
                    // Background circle
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    // Bell icon
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    // Notification badge
                    if !connectionService.pendingRequests.isEmpty {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Text("\(connectionService.pendingRequests.count)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 12, y: -12)
                    }
                }
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
    
    // Pulse animation for the logo
    struct PulseAnimation: ViewModifier {
        @State private var isPulsing = false
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(isPulsing ? 1.05 : 1)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                    ) {
                        isPulsing = true
                    }
                }
        }
    }
    
    // Floating animation for cards
    struct FloatAnimation: ViewModifier {
        @State private var isFloating = false
        let delay: Double
        
        func body(content: Content) -> some View {
            content
                .offset(y: isFloating ? -5 : 5)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                    ) {
                        isFloating = true
                    }
                }
        }
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
