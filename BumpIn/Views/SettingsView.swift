import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var cardService: BusinessCardService
    @State private var showSignOutAlert = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showFullCard = false
    @State private var showSettingsMenu = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Profile Header Card
                    VStack(spacing: 0) {
                        if let card = cardService.userCard {
                            card.colorScheme.backgroundView(style: .gradient)
                                .frame(height: 120)
                                .overlay {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showSignOutAlert = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showFullCard) {
                if let card = cardService.userCard {
                    CardDetailView(card: card, selectedImage: nil)
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    do {
                        try authService.signOut()
                    } catch {
                        showError = true
                        errorMessage = error.localizedDescription
                    }
                }
            }
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