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
            
            // Contacts Tab
            contactsView
                .tabItem {
                    Label("Contacts", systemImage: "person.2.fill")
                }
                .tag(1)
            
            // Profile Tab
            profileView
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(2)
        }
        .tint(Color(red: 0.1, green: 0.3, blue: 0.5))
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showCreateCard) {
            if let existingCard = cardService.userCard {
                CreateCardView(cardService: cardService, existingCard: existingCard)
            } else {
                CreateCardView(cardService: cardService)
            }
        }
        .sheet(isPresented: $showCardDetail) {
            if let card = cardService.userCard {
                CardDetailView(card: card)
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
            ScrollView {
                VStack(spacing: 25) {
                    // Header with welcome and profile
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome Back")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text(authService.user?.email ?? "")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        
                        Button(action: {
                            showSignOutAlert = true
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 5)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Main Create Card Button
                    Button(action: {
                        showCreateCard = true
                    }) {
                        VStack(spacing: 16) {
                            Image(systemName: cardService.userCard == nil ? "square.and.pencil" : "square.and.pencil.circle.fill")
                                .font(.system(size: 40))
                            Text(cardService.userCard == nil ? "Create Your Business Card" : "Edit Your Business Card")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.1, green: 0.3, blue: 0.5),
                                    Color(red: 0.2, green: 0.4, blue: 0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color(red: 0.1, green: 0.3, blue: 0.5).opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal)
                    
                    // Secondary Actions
                    HStack(spacing: 15) {
                        // Your Card Button
                        Button(action: {
                            if cardService.userCard != nil {
                                showCardDetail = true
                            } else {
                                showCreateCard = true
                            }
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "person.text.rectangle.fill")
                                    .font(.system(size: 24))
                                Text("Your Card")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.2, green: 0.4, blue: 0.6),
                                        Color(red: 0.3, green: 0.5, blue: 0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(15)
                        }
                        
                        // Scan Card Button
                        Button(action: {
                            // TODO: Implement scanning
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 24))
                                Text("Scan Card")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.3, green: 0.5, blue: 0.7),
                                        Color(red: 0.4, green: 0.6, blue: 0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Contacts Section with new design
                    if !cardService.recentContacts.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Recent Contacts")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Button("See All") {
                                    selectedTab = 1
                                }
                                .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(cardService.recentContacts) { contact in
                                        ContactPreviewCard(card: contact)
                                            .shadow(color: .black.opacity(0.1), radius: 5)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
    
    private var contactsView: some View {
        NavigationView {
            List {
                if cardService.contacts.isEmpty {
                    Text("No contacts yet")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                } else {
                    ForEach(cardService.contacts) { contact in
                        ContactListItem(card: contact)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    if let userId = authService.user?.uid {
                                        Task {
                                            try? await cardService.removeContact(cardId: contact.id, userId: userId)
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .navigationTitle("Contacts")
            .refreshable {
                if let userId = authService.user?.uid {
                    try? await cardService.fetchContacts(userId: userId)
                }
            }
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
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(card.name.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined())
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                
                if !card.title.isEmpty && !card.company.isEmpty {
                    Text("\(card.title) • \(card.company)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                } else if !card.title.isEmpty {
                    Text(card.title)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                } else if !card.company.isEmpty {
                    Text(card.company)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
} 