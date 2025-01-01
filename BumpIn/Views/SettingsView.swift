import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var cardService: BusinessCardService
    @State private var showSignOutAlert = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = true
    @State private var showSettingsMenu = false
    @State private var preloadedImage: UIImage?
    @StateObject private var storageService = StorageService()
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Profile Header Card
                            VStack(spacing: 0) {
                                if let card = cardService.userCard {
                                    card.colorScheme.backgroundView(style: .gradient)
                                        .frame(height: 120)
                                        .overlay {
                                            if let image = preloadedImage {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipShape(Circle())
                                                    .overlay(Circle().stroke(.white, lineWidth: 3))
                                                    .shadow(radius: 5)
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
                                
                                VStack(spacing: 8) {
                                    if let user = userService.currentUser {
                                        Text("@\(user.username)")
                                            .font(.title2.bold())
                                            .padding(.top, 60)
                                    }
                                    
                                    if let card = cardService.userCard {
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
                                }
                                .padding(.bottom, 20)
                            }
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.1), radius: 10)
                            .padding()
                            
                            // Business Card Section
                            if let card = cardService.userCard {
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
                            
                            // Contact Info Section
                            if let card = cardService.userCard {
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
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettingsMenu = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    .sheet(isPresented: $showSettingsMenu) {
                        NavigationView {
                            List {
                                Section {
                                    Button(action: {
                                        showSettingsMenu = false
                                        showSignOutAlert = true
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                                .font(.system(size: 18))
                                                .foregroundColor(.red)
                                                .frame(width: 28)
                                            
                                            Text("Sign Out")
                                                .foregroundColor(.red)
                                        }
                                    }
                                } header: {
                                    Text("Account")
                                }
                            }
                            .navigationTitle("Settings")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") {
                                        showSettingsMenu = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showSignOutAlert) {
                ZStack {
                    // Background blur
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    
                    // Content
                    VStack(spacing: 0) {
                        // Header with icon
                        VStack(spacing: 16) {
                            ZStack {
                                // Background circles for depth
                                Circle()
                                    .fill(Color.red.opacity(0.1))
                                    .frame(width: 100, height: 100)
                                Circle()
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                
                                // Icon
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Sign Out")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                if let username = userService.currentUser?.username {
                                    Text("Are you sure you want to sign out")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                    Text("@\(username)?")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 24)
                        
                        // Divider
                        Divider()
                            .padding(.horizontal, 24)
                        
                        // Buttons
                        VStack(spacing: 12) {
                            // Sign Out button
                            Button {
                                do {
                                    try authService.signOut()
                                } catch {
                                    showError = true
                                    errorMessage = error.localizedDescription
                                }
                            } label: {
                                Text("Sign Out")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.red)
                                    .cornerRadius(12)
                            }
                            
                            // Cancel button
                            Button {
                                showSignOutAlert = false
                            } label: {
                                Text("Cancel")
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
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        if let card = cardService.userCard, let imageURL = card.profilePictureURL {
            if let image = try? await storageService.loadProfileImage(from: imageURL) {
                await MainActor.run {
                    preloadedImage = image
                }
            }
        }
        await MainActor.run {
            isLoading = false
        }
    }
    
    private var defaultProfileImage: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 86, height: 86)
            .overlay(
                Text(String(userService.currentUser?.username.prefix(1).uppercased() ?? ""))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.gray)
            )
    }
} 