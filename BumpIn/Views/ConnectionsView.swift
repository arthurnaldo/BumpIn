import SwiftUI

struct ConnectionsView: View {
    @EnvironmentObject var connectionService: ConnectionService
    @EnvironmentObject var userService: UserService
    @State private var searchText = ""
    @State private var isLoading = true
    @Namespace private var animation
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                } else if searchText.isEmpty && connectionService.connections.isEmpty {
                    ContentUnavailableView(
                        "No Connections",
                        systemImage: "person.2.slash",
                        description: Text("Search to connect with others")
                    )
                } else if userService.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
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
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
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
                                    
                                    // Card preview if available
                                    if let card = user.card {
                                        BusinessCardPreview(card: card, showFull: false, selectedImage: nil)
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
                            .transition(.move(edge: .trailing))
                        }
                        .padding(.horizontal, CardDimensions.horizontalPadding)
                    }
                    .padding(.vertical, CardDimensions.horizontalPadding)
                }
            }
            .animation(.spring(
                response: CardDimensions.transitionDuration,
                dampingFraction: CardDimensions.springDamping
            ), value: searchText)
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
        } catch {
            print("Failed to fetch data: \(error.localizedDescription)")
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
} 