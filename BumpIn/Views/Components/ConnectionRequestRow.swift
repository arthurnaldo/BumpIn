import SwiftUI

struct ConnectionRequestRow: View {
    let request: ConnectionRequest
    @EnvironmentObject var connectionService: ConnectionService
    @State private var isLoading = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("@\(request.fromUsername)")
                    .font(.headline)
                Text("Wants to connect")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if !isLoading {
                HStack(spacing: 12) {
                    Button {
                        handleRequest()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    Button {
                        connectionService.pendingRequests.removeAll { $0.id == request.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func handleRequest() {
        isLoading = true
        Task {
            do {
                try await connectionService.handleConnectionRequest(request, accept: true)
            } catch {
                print("Error handling request: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
} 