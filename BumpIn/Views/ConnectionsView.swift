import SwiftUI

struct ConnectionsView: View {
    @EnvironmentObject var connectionService: ConnectionService
    @EnvironmentObject var userService: UserService
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var preloadedImages: [String: UIImage] = [:]
    @Namespace private var animation
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .transition(.opacity)
                } else {
                    ScrollView {
                        if searchText.isEmpty && connectionService.connections.isEmpty {
                            ContentUnavailableView(
                                "No Connections",
                                systemImage: "person.2.slash",
                                description: Text("Search to connect with others")
                            )
                            .transition(.opacity)
                        } else if userService.isSearching {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 100)
                                .transition(.opacity)
                        } else if !searchText.isEmpty {
                            // Search results view
                            LazyVStack(spacing: 0) {
                                ForEach(userService.searchResults.sorted { user1, user2 in
                                    // Connected users first
                                    let isConnected1 = connectionService.connections.contains { $0.id == user1.id }
                                    let isConnected2 = connectionService.connections.contains { $0.id == user2.id }
                                    if isConnected1 != isConnected2 {
                                        return isConnected1
                                    }
                                    return user1.username < user2.username
                                }) { user in
                                    NavigationLink(destination: UserProfileView(user: user).environmentObject(connectionService)) {
                                        NetworkUserRow(
                                            user: user,
                                            showConnectionStatus: true,
                                            isConnected: connectionService.connections.contains { $0.id == user.id }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                         removal: .opacity))
                                    Divider()
                                }
                            }
                            .background(Color(uiColor: .systemBackground))
                        } else {
                            // Connections view
                            LazyVStack(spacing: CardDimensions.horizontalPadding) {
                                ForEach(connectionService.connections) { user in
                                    NavigationLink(destination: UserProfileView(user: user).environmentObject(connectionService)) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            // Username and connection status
                                            HStack {
                                                Text("@\(user.username)")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                
                                                Spacer()
                                                
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            }
                                            .opacity(isRefreshing ? 0.6 : 1.0)
                                            
                                            // Card preview if available
                                            if let card = user.card {
                                                BusinessCardPreview(
                                                    card: card,
                                                    showFull: false,
                                                    selectedImage: preloadedImages[card.profilePictureURL ?? ""]
                                                )
                                                .frame(height: CardDimensions.previewHeight)
                                            }
                                        }
                                        .padding(CardDimensions.horizontalPadding)
                                        .background(Color(uiColor: .systemBackground))
                                        .cornerRadius(CardDimensions.cornerRadius)
                                        .shadow(
                                            color: .black.opacity(CardDimensions.shadowOpacity),
                                            radius: CardDimensions.shadowRadius
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity),
                                                         removal: .opacity))
                                }
                                .padding(.horizontal, CardDimensions.horizontalPadding)
                            }
                            .padding(.vertical, CardDimensions.horizontalPadding)
                        }
                    }
                    .refreshable {
                        isRefreshing = true
                        await fetchData()
                        try? await Task.sleep(nanoseconds: 200_000_000) // Add slight delay for smoother transition
                        withAnimation(.easeOut(duration: 0.2)) {
                            isRefreshing = false
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isLoading)
            .animation(.easeInOut(duration: 0.3), value: searchText)
            .animation(.easeInOut(duration: 0.3), value: userService.isSearching)
            .animation(.easeInOut(duration: 0.3), value: connectionService.connections)
            .navigationTitle("Network")
            .searchable(text: $searchText, prompt: "Search users")
            .onChange(of: searchText) { _, newValue in
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if searchText == newValue {
                        try? await userService.searchUsers(query: newValue)
                    }
                }
            }
        }
        .task {
            await fetchData()
        }
    }
    
    private func fetchData() async {
        do {
            try await connectionService.fetchConnections()
            
            // Preload all profile images
            let storageService = StorageService()
            for user in connectionService.connections {
                if let card = user.card, let imageURL = card.profilePictureURL {
                    if let image = try? await storageService.loadProfileImage(from: imageURL) {
                        await MainActor.run {
                            preloadedImages[imageURL] = image
                        }
                    }
                }
            }
        } catch {
            print("Failed to fetch data: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
} 