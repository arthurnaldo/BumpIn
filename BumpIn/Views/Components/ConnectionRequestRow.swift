import SwiftUI

struct ConnectionRequestRow: View {
    let request: ConnectionRequest
    @EnvironmentObject var connectionService: ConnectionService
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("@\(request.fromUsername)")
                    .font(.headline)
                Text("Wants to connect")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if !isLoading {
                HStack(spacing: 8) {
                    // Accept Button
                    Button {
                        handleRequest(accept: true)
                    } label: {
                        Text("Accept")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 72, height: 30)
                            .background(Color.blue)
                            .cornerRadius(6)
                    }
                    
                    // Ignore Button
                    Button {
                        handleRequest(accept: false)
                    } label: {
                        Text("Ignore")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 72, height: 30)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                    }
                }
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func handleRequest(accept: Bool) {
        isLoading = true
        Task {
            do {
                try await connectionService.handleConnectionRequest(request, accept: accept)
            } catch {
                print("Error handling request: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
} 