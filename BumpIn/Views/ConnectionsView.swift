import SwiftUI

struct ConnectionsView: View {
    @EnvironmentObject var connectionService: ConnectionService
    @EnvironmentObject var userService: UserService
    @State private var searchText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty && connectionService.connections.isEmpty {
                    ContentUnavailableView(
                        "No Connections",
                        systemImage: "person.2.slash",
                        description: Text("Search to connect with others")
                    )
                } else if userService.isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    // Show filtered results with connected users first
                    let searchResults = searchText.isEmpty 
                        ? connectionService.connections 
                        : userService.searchResults
                    
                    ForEach(searchResults.sorted { user1, user2 in
                        // Connected users always come first
                        let isConnected1 = connectionService.connections.contains { $0.id == user1.id }
                        let isConnected2 = connectionService.connections.contains { $0.id == user2.id }
                        if isConnected1 != isConnected2 {
                            return isConnected1
                        }
                        return user1.username < user2.username
                    }) { user in
                        NavigationLink(destination: UserProfileView(user: user)) {
                            NetworkUserRow(
                                user: user,
                                showConnectionStatus: true,
                                isConnected: connectionService.connections.contains { $0.id == user.id }
                            )
                        }
                        .swipeActions(edge: .trailing) {
                            if connectionService.connections.contains(where: { $0.id == user.id }) {
                                DisconnectButton(userId: user.id)
                            }
                        }
                    }
                }
            }
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
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
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
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Supporting Views
struct DisconnectButton: View {
    let userId: String
    @EnvironmentObject var connectionService: ConnectionService
    
    var body: some View {
        Button(role: .destructive) {
            Task {
                try? await connectionService.removeConnection(with: userId)
            }
        } label: {
            Label("Disconnect", systemImage: "person.badge.minus")
        }
    }
} 