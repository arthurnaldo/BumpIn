import SwiftUI
import FirebaseAuth

struct MainView: View {
    @Binding var isAuthenticated: Bool
    @StateObject private var authService = AuthenticationService()
    @StateObject private var cardService = BusinessCardService()
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
    
    private func fetchUserCard() {
        guard let userId = authService.user?.uid else { return }
        
        Task {
            do {
                if let card = try await cardService.fetchUserCard(userId: userId) {
                    cardService.userCard = card
                }
                try await cardService.fetchContacts(userId: userId)
            } catch {
                if (error as NSError).domain == "FIRFirestoreErrorDomain" {
                    print("First-time user or document doesn't exist yet")
                } else {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            homeView
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            cardsView
                .tabItem {
                    Label("Cards", systemImage: "rectangle.stack.fill")
                }
                .tag(1)
            
            NavigationView {
                if let existingCard = cardService.userCard {
                    CreateCardView(cardService: cardService, existingCard: existingCard)
                } else {
                    CreateCardView(cardService: cardService)
                }
            }
            .tabItem {
                Label("Edit Card", systemImage: "pencil.circle.fill")
            }
            .tag(2)
            
            ShareCardView()
                .environmentObject(cardService)
                .tabItem {
                    Label("Share", systemImage: "square.and.arrow.up")
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
        .onAppear {
            fetchUserCard()
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
                VStack(spacing: 24) {
                    // Header with Settings Popover
                    HStack(spacing: 16) {
                        if let card = cardService.userCard {
                            Text("Welcome, \(card.name.components(separatedBy: " ").first ?? "")")
                                .font(.system(size: 24, weight: .semibold))
                        } else {
                            Text("Welcome")
                                .font(.system(size: 24, weight: .semibold))
                        }
                        
                        Spacer()
                        
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primary)
                        }
                        .popover(isPresented: $showSettings) {
                            VStack(spacing: 16) {
                                Text("Settings")
                                    .font(.headline)
                                    .foregroundColor(isDarkMode ? .white : .black)
                                    .padding(.top)
                                
                                Divider()
                                    .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                                
                                // Animated Theme Toggle
                                Button(action: {
                                    withAnimation {
                                        isDarkMode.toggle()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(isDarkMode ? .white : .black)
                                            .matchedGeometryEffect(id: "themeIcon", in: themeAnimation)
                                        
                                        Text(isDarkMode ? "Dark Mode" : "Light Mode")
                                            .foregroundColor(isDarkMode ? .white : .black)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(isDarkMode ? Color.black : Color.white)
                                            .shadow(color: .black.opacity(0.1), radius: 5)
                                    )
                                }
                                
                                Button(action: { showSignOutAlert = true }) {
                                    Text("Sign Out")
                                        .foregroundColor(.red)
                                }
                                .padding(.bottom)
                            }
                            .frame(width: 200)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Your Card Section
                    if let card = cardService.userCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Card")
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal)
                            
                            BusinessCardPreview(card: card, showFull: false, selectedImage: selectedImage)
                                .padding(.horizontal)
                                .onTapGesture {
                                    showExpandedCard = true
                                }
                            
                            // Quick Actions
                            HStack(spacing: 20) {
                                Button(action: { selectedTab = 2 }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(card.colorScheme.primary)
                                        Text("Edit")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(card.colorScheme.primary)
                                    }
                                }
                                
                                Button(action: { selectedTab = 3 }) {
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
                            .padding(.vertical, 20)
                        }
                    } else {
                        // Create Card Button
                        Button(action: { selectedTab = 2 }) {
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
                        .padding()
                    }
                    
                    // Recent Contacts Section
                    if !cardService.recentContacts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Contacts")
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(cardService.recentContacts) { card in
                                        BusinessCardPreview(card: card, showFull: false, selectedImage: nil)
                                            .frame(width: 300)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var cardsView: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(cardService.contacts) { card in
                        BusinessCardPreview(card: card, showFull: false, selectedImage: nil)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Contacts")
        }
    }
} 