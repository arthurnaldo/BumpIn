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
    
    private func fetchUserCard() {
        guard let userId = authService.user?.uid else { return }
        
        Task {
            do {
                // Fetch user's card
                if let card = try await cardService.fetchUserCard(userId: userId) {
                    cardService.userCard = card
                }
                
                // Fetch user's contacts
                try await cardService.fetchContacts(userId: userId)
            } catch {
                if (error as NSError).domain == "FIRFirestoreErrorDomain" {
                    // This is likely a first-time user, so we can ignore the error
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
            // Home Tab
            homeView
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            // Cards Tab
            cardsView
                .tabItem {
                    Label("Cards", systemImage: "rectangle.stack.fill")
                }
                .tag(1)
            
            // Edit Card Tab
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
            
            // Share Card Tab
            ShareCardView()
                .environmentObject(cardService)
                .tabItem {
                    Label("Share Card", systemImage: "square.and.arrow.up.fill")
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
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        isDarkMode.toggle()
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        // Theme Icon with animation
                                        ZStack {
                                            if isDarkMode {
                                                Image(systemName: "moon.fill")
                                                    .matchedGeometryEffect(id: "themeIcon", in: themeAnimation)
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.white)
                                            } else {
                                                Image(systemName: "sun.max.fill")
                                                    .matchedGeometryEffect(id: "themeIcon", in: themeAnimation)
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(isDarkMode ? Color.white.opacity(0.1) : Color.orange.opacity(0.1))
                                        )
                                        
                                        Text(isDarkMode ? "Dark Mode" : "Light Mode")
                                            .foregroundColor(isDarkMode ? .white : .black)
                                            .font(.system(.body, design: .rounded))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
                                    .cornerRadius(10)
                                    .contentShape(Rectangle())
                                }
                                
                                Divider()
                                    .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                                
                                Button(action: { 
                                    showSettings = false
                                    showSignOutAlert = true 
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 18))
                                            .foregroundColor(.red)
                                            .frame(width: 32, height: 32)
                                            .background(
                                                Circle()
                                                    .fill(Color.red.opacity(isDarkMode ? 0.15 : 0.1))
                                            )
                                        Text("Sign Out")
                                            .font(.system(.body, design: .rounded))
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(isDarkMode ? 0.1 : 0.05))
                                    .cornerRadius(10)
                                }
                                .padding(.bottom)
                            }
                            .frame(width: 220)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isDarkMode ? Color(uiColor: .systemGray5) : .white)
                            )
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isDarkMode)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Your Card Section
                    if let card = cardService.userCard {
                        VStack(spacing: 0) {
                            // Card Preview
                            Button(action: { showCardDetail = true }) {
                                CardPreviewContainer(businessCard: card, selectedImage: nil)
                                    .frame(height: 286)
                            }
                            
                            // Quick Actions Bar
                            HStack(spacing: 30) {
                                Button(action: { selectedTab = 2 }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 28))
                                        Text("Edit")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                }
                                
                                Button(action: { selectedTab = 3 }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.up.circle.fill")
                                            .font(.system(size: 28))
                                        Text("Share & Scan")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                }
                            }
                            .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
                            .padding(.vertical, 16)
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 2)
                        .padding(.horizontal)
                    } else {
                        // Create First Card Prompt
                        Button(action: { showCreateCard = true }) {
                            VStack(spacing: 20) {
                                Image(systemName: "rectangle.stack.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
                                
                                Text("Create Your First Card")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Text("Start networking by creating your digital business card")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 2)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
    
    private struct NetworkStatView: View {
        let number: Int
        let label: String
        
        var body: some View {
            VStack(spacing: 6) {
                Text("\(number)")
                    .font(.system(size: 22, weight: .bold))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
        }
    }
    
    private struct HingeStyleCardPreview: View {
        let card: BusinessCard
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Profile Initial with Gradient Background
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [card.colorScheme.primary, card.colorScheme.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 70, height: 70)
                    
                    Text(card.name.prefix(1))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.name)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                    
                    if !card.title.isEmpty {
                        Text(card.title)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    if !card.company.isEmpty {
                        Text(card.company)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: 180)
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        }
    }
    
    private var cardsView: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if cardService.contacts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "rectangle.stack.person.crop")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No cards yet")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            Text("Cards you collect will appear here")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(cardService.contacts) { contact in
                            NavigationLink(destination: CardDetailView(card: contact, selectedImage: nil)) {
                                ContactListItem(card: contact)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Cards")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var profileView: some View {
        NavigationView {
            VStack {
                if let card = cardService.userCard {
                    ScrollView {
                        VStack(spacing: 20) {
                            BusinessCardPreview(card: card, showFull: true)
                                .padding()
                            
                            Button(action: {
                                showCreateCard = true
                            }) {
                                Label("Edit Card", systemImage: "pencil")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [card.colorScheme.primary, card.colorScheme.secondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "person.text.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Business Card")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Create your business card to share with others")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            showCreateCard = true
                        }) {
                            Text("Create Card")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.1, green: 0.3, blue: 0.5))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5)
        }
    }
}

struct ContactPreviewCard: View {
    let card: BusinessCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(card.name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined())
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                    
                    if !card.title.isEmpty {
                        Text(card.title)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            if !card.company.isEmpty {
                Text(card.company)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(width: 250)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

struct ContactListItem: View {
    let card: BusinessCard
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Modern circular avatar with gradient background
                Circle()
                    .fill(LinearGradient(
                        colors: [card.colorScheme.primary, card.colorScheme.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(card.name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined())
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                    )
                    .shadow(color: card.colorScheme.primary.opacity(0.3), radius: 5)
                    .matchedGeometryEffect(id: "avatar_\(card.id)", in: animation)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .matchedGeometryEffect(id: "name_\(card.id)", in: animation)
                    
                    if !card.title.isEmpty && !card.company.isEmpty {
                        Text("\(card.title) • \(card.company)")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .matchedGeometryEffect(id: "details_\(card.id)", in: animation)
                    } else if !card.title.isEmpty {
                        Text(card.title)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                            .matchedGeometryEffect(id: "title_\(card.id)", in: animation)
                    } else if !card.company.isEmpty {
                        Text(card.company)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.gray)
                            .matchedGeometryEffect(id: "company_\(card.id)", in: animation)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(colorScheme == .dark ? Color(uiColor: .systemGray6) : .white)
            .contentShape(Rectangle())
            
            // Bottom border with gradient
            Rectangle()
                .fill(LinearGradient(
                    colors: [card.colorScheme.primary.opacity(0.2), card.colorScheme.secondary.opacity(0.2)],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 1)
        }
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }
} 