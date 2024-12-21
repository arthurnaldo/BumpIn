import SwiftUI

struct ConnectionsView: View {
    @EnvironmentObject var connectionService: ConnectionService
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom segmented control
                HStack(spacing: 0) {
                    TabButton(title: "Connections (\(connectionService.connections.count))", 
                             isSelected: selectedTab == 0) {
                        withAnimation {
                            selectedTab = 0
                        }
                    }
                    
                    TabButton(title: "Requests (\(connectionService.pendingRequests.count))", 
                             isSelected: selectedTab == 1) {
                        withAnimation {
                            selectedTab = 1
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                TabView(selection: $selectedTab) {
                    // Connections Tab
                    ConnectionsList(
                        connections: connectionService.connections,
                        errorMessage: $errorMessage,
                        showError: $showError
                    )
                    .environmentObject(connectionService)
                    .tag(0)
                    
                    // Requests Tab
                    RequestsList(
                        requests: connectionService.pendingRequests,
                        onAccept: { request in
                            handleRequest(request, accept: true)
                        },
                        onReject: { request in
                            handleRequest(request, accept: false)
                        }
                    )
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Network")
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
    
    private func handleRequest(_ request: ConnectionRequest, accept: Bool) {
        Task {
            do {
                try await connectionService.handleConnectionRequest(request, accept: accept)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Supporting Views
private struct ConnectionsList: View {
    let connections: [User]
    @EnvironmentObject var connectionService: ConnectionService
    @Binding var errorMessage: String
    @Binding var showError: Bool
    
    var body: some View {
        if connections.isEmpty {
            ContentUnavailableView(
                "No Connections",
                systemImage: "person.2.slash",
                description: Text("Connect with others to grow your network")
            )
        } else {
            List(connections) { user in
                NavigationLink(destination: UserProfileView(user: user)) {
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
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task {
                            do {
                                try await connectionService.removeConnection(with: user.id)
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    } label: {
                        Label("Disconnect", systemImage: "person.badge.minus")
                    }
                }
            }
        }
    }
}

private struct RequestsList: View {
    let requests: [ConnectionRequest]
    let onAccept: (ConnectionRequest) -> Void
    let onReject: (ConnectionRequest) -> Void
    
    var body: some View {
        if requests.isEmpty {
            ContentUnavailableView(
                "No Pending Requests",
                systemImage: "person.crop.circle.badge.questionmark",
                description: Text("You don't have any connection requests")
            )
        } else {
            List(requests) { request in
                VStack(alignment: .leading, spacing: 8) {
                    Text("@\(request.fromUsername)")
                        .font(.headline)
                    
                    Text("Wants to connect with you")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Button(action: { onAccept(request) }) {
                            Text("Accept")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button(action: { onReject(request) }) {
                            Text("Decline")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Namespace private var namespace
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .foregroundColor(isSelected ? .primary : .gray)
        }
        .background(
            VStack {
                Spacer()
                if isSelected {
                    Color.blue
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "tab", in: namespace)
                } else {
                    Color.clear.frame(height: 2)
                }
            }
        )
    }
} 