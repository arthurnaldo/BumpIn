import SwiftUI

struct ConnectionsView: View {
    @EnvironmentObject var connectionService: ConnectionService
    @EnvironmentObject var userService: UserService
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var preloadedImages: [String: UIImage] = [:]
    @Namespace private var animation
    @State private var isRefreshing = false
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .transition(.opacity)
                } else {
                    VStack(spacing: 0) {
                        // Custom Search Bar
                        HStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 18))
                                    .foregroundColor(.black)
                                
                                TextField("", text: $searchText, prompt: Text("Search users")
                                    .foregroundColor(.black.opacity(0.8)))
                                    .font(.system(size: 17))
                                    .focused($isSearchFocused)
                                    .foregroundColor(.black)
                                    .tint(.black)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                
                                if !searchText.isEmpty {
                                    Button {
                                        searchText = ""
                                        isSearchFocused = false
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.black)
                                            .font(.system(size: 17))
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                            )
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        
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
                            try? await Task.sleep(nanoseconds: 200_000_000)
                            withAnimation(.easeOut(duration: 0.2)) {
                                isRefreshing = false
                            }
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isLoading)
            .animation(.easeInOut(duration: 0.3), value: searchText)
            .animation(.easeInOut(duration: 0.3), value: userService.isSearching)
            .animation(.easeInOut(duration: 0.3), value: connectionService.connections)
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

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
} 