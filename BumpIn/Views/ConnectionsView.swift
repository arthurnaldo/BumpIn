import SwiftUI

struct ConnectionsView: View {
    @EnvironmentObject var connectionService: ConnectionService
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ConnectionsList()
                .environmentObject(connectionService)
            .navigationTitle("Network")
            .navigationDestination(for: User.self) { user in
                UserProfileView(user: user)
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
private struct ConnectionsList: View {
    @EnvironmentObject var connectionService: ConnectionService
    
    var body: some View {
        NavigationStack {
            if connectionService.connections.isEmpty {
                ContentUnavailableView(
                    "No Connections",
                    systemImage: "person.2.slash",
                    description: Text("Connect with others to grow your network")
                )
            } else {
                List(connectionService.connections) { user in
                    NavigationLink(value: user) {
                        UserRow(user: user)
                    }
                    .swipeActions(edge: .trailing) {
                        DisconnectButton(userId: user.id)
                    }
                }
                .navigationDestination(for: User.self) { user in
                    UserProfileView(user: user)
                }
            }
        }
    }
}

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

struct ActionButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary
        
        var background: Color {
            switch self {
            case .primary: return .blue
            case .secondary: return .gray.opacity(0.2)
            }
        }
        
        var foreground: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .primary
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(style.background)
                .foregroundColor(style.foreground)
                .cornerRadius(8)
        }
    }
} 