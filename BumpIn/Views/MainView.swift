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
    @State private var isCardZoomed = false
    @State private var showExpandedCard = false
    
    private func fetchInitialData() async {
        guard let userId = authService.user?.uid else { return }
        
        do {
            // Fetch user data
            try await userService.fetchCurrentUser()
            
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
                            HStack(spacing: 16) {
                                NotificationButton()
                                    .environmentObject(connectionService)
                                Button(action: { showSettings = true }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 20))
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
                    CreateCardView(cardService: cardService, existingCard: existingCard)
                } else {
                    CreateCardView(cardService: cardService)
                }
            }
            .tabItem {
                Label("My Card", systemImage: "person.crop.rectangle.fill")
            }
            .tag(1)
            
            SearchView()
                .environmentObject(userService)
                .tabItem {
                    Label("Match", systemImage: "sparkles")
                }
                .tag(2)
            
            ConnectionsView()
                .environmentObject(connectionService)
                .tabItem {
                    Label("Network", systemImage: "person.2.fill")
                }
                .tag(3)
            
            SettingsView()
                .environmentObject(userService)
                .environmentObject(authService)
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(4)
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
        .sheet(isPresented: $showExpandedCard) {
            if let card = cardService.userCard {
                ZoomableCardView(card: card, selectedImage: nil)
            }
        }
    }
    
    private var homeView: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Welcome Text
                    HStack(spacing: 16) {
                        if let card = cardService.userCard {
                            Text("Welcome, \(card.name.components(separatedBy: " ").first ?? "")")
                                .font(.system(size: 24, weight: .semibold))
                        } else {
                            Text("Welcome")
                                .font(.system(size: 24, weight: .semibold))
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Card Section
                    if let card = cardService.userCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Card")
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal)
                            
                            BusinessCardPreview(card: card, showFull: false, selectedImage: nil)
                                .frame(height: 200)
                                .onTapGesture {
                                    showExpandedCard = true
                                }
                                .padding(.horizontal)
                            
                            // Quick Actions
                            HStack(spacing: 20) {
                                Button(action: { selectedTab = 1 }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(card.colorScheme.primary)
                                        Text("Edit")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(card.colorScheme.primary)
                                    }
                                }
                                
                                Button(action: { showCardDetail = true }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 28))
                                            .foregroundColor(card.colorScheme.primary)
                                        Text("Share")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(card.colorScheme.primary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                    } else {
                        // Create Card Button
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
                    
                    // Contacts Grid
                    if !cardService.contacts.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Recent Connections")
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(cardService.contacts) { card in
                                    ContactBox(card: card)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
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