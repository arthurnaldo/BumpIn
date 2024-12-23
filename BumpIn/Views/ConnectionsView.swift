import SwiftUI

struct ConnectionsView: View {
    @EnvironmentObject var connectionService: ConnectionService
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control
                CustomSegmentedControl(
                    selection: $selectedTab,
                    items: [
                        .init(title: "Connections", count: connectionService.connections.count),
                        .init(title: "Requests", count: connectionService.pendingRequests.count)
                    ]
                )
                .padding(.horizontal)
                
                // Content
                TabView(selection: $selectedTab) {
                    ConnectionsList()
                        .environmentObject(connectionService)
                        .tag(0)
                    
                    RequestsList()
                        .environmentObject(connectionService)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
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
            try await connectionService.fetchPendingRequests()
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

private struct RequestsList: View {
    @EnvironmentObject var connectionService: ConnectionService
    
    var body: some View {
        if connectionService.pendingRequests.isEmpty {
            ContentUnavailableView(
                "No Requests",
                systemImage: "person.crop.circle.badge.questionmark",
                description: Text("You don't have any connection requests")
            )
        } else {
            List(connectionService.pendingRequests) { request in
                RequestRow(request: request)
            }
        }
    }
}

// MARK: - Reusable Components
struct RequestRow: View {
    let request: ConnectionRequest
    @EnvironmentObject var connectionService: ConnectionService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("@\(request.fromUsername)")
                .font(.headline)
            
            Text("Wants to connect with you")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack(spacing: 12) {
                ActionButton(title: "Accept", style: .primary) {
                    handleRequest(accept: true)
                }
                
                ActionButton(title: "Decline", style: .secondary) {
                    handleRequest(accept: false)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func handleRequest(accept: Bool) {
        Task {
            try? await connectionService.handleConnectionRequest(request, accept: accept)
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

struct CustomSegmentedControl: View {
    @Binding var selection: Int
    let items: [Item]
    @Namespace private var namespace
    
    struct Item {
        let title: String
        let count: Int
        
        var displayText: String {
            "\(title) (\(count))"
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = index
                    }
                } label: {
                    Text(items[index].displayText)
                        .font(.system(.headline, design: .rounded))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(selection == index ? .primary : .gray)
                }
                .background(
                    VStack {
                        Spacer()
                        if selection == index {
                            Color.blue
                                .frame(height: 2)
                                .matchedGeometryEffect(id: "tab", in: namespace)
                        }
                    }
                )
            }
        }
    }
} 