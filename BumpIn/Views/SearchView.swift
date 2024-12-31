import SwiftUI

struct SearchView: View {
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var connectionService: ConnectionService
    @State private var searchText = ""
    @State private var debouncedSearchText = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Results
                if userService.isSearching {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxHeight: .infinity)
                } else if searchText.isEmpty {
                    ContentUnavailableView(
                        "Search Users",
                        systemImage: "magnifyingglass",
                        description: Text("Search for users by username")
                    )
                } else if userService.searchResults.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "person.slash",
                        description: Text("No users found matching '\(searchText)'")
                    )
                } else {
                    List(userService.searchResults) { user in
                        NavigationLink(destination: UserProfileView(user: user).environmentObject(connectionService)) {
                            UserRow(user: user)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                blockUser(user.id)
                            } label: {
                                Label("Block", systemImage: "slash.circle")
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Search")
            .onChange(of: searchText) { _, newValue in
                // Debounce search
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
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
    }
    
    private func blockUser(_ userId: String) {
        Task {
            do {
                try await userService.blockUser(userId)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct UserRow: View {
    let user: User
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.username.prefix(1).uppercased()))
                        .font(.headline)
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading) {
                Text("@\(user.username)")
                    .font(.headline)
                if let card = user.card {
                    Text(card.title)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
    }
} 