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
        }
        .tint(Color(red: 0.1, green: 0.3, blue: 0.5))
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
                                    .padding(.top)
                                
                                Divider()
                                
                                Button(action: { 
                                    showSettings = false
                                    showImagePicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "person.crop.circle")
                                        Text("Change Profile Picture")
                                    }
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                }
                                
                                Button(action: { 
                                    showSettings = false
                                    showSignOutAlert = true 
                                }) {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("Sign Out")
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                                }
                                .padding(.bottom)
                            }
                            .frame(width: 200)
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
                                
                                Button(action: { /* TODO: Share */ }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.up.circle.fill")
                                            .font(.system(size: 28))
                                        Text("Share")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                }
                                
                                Button(action: { /* TODO: Implement scanning */ }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "qrcode.viewfinder")
                                            .font(.system(size: 28))
                                        Text("Scan")
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
                    
                    // Network Stats
                    HStack(spacing: 20) {
                        NetworkStatView(number: cardService.contacts.count, label: "Cards")
                        NetworkStatView(number: cardService.recentContacts.count, label: "Recent")
                        NetworkStatView(number: 0, label: "Pending")
                    }
                    .padding(.horizontal)
                    
                    // Recent Cards Section
                    if !cardService.recentContacts.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Connections")
                                    .font(.system(size: 20, weight: .semibold))
                                Spacer()
                                Button("View All") {
                                    selectedTab = 1
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
                            }
                            .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(cardService.recentContacts) { contact in
                                        NavigationLink {
                                            CardDetailView(card: contact, selectedImage: nil)
                                        } label: {
                                            HingeStyleCardPreview(card: contact)
                                                .shadow(color: (cardService.userCard?.colorScheme.primary ?? Color.black).opacity(0.05), radius: 8, y: 2)
                                        }
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
            List {
                if cardService.contacts.isEmpty {
                    Text("No cards yet")
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
                                .tint(.red)
                            }
                    }
                }
            }
            .navigationTitle("Cards")
            .tint(Color(red: 0.1, green: 0.3, blue: 0.5))
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