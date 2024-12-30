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
                        handleRequest(accept: true)
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    Button {
                        handleRequest(accept: false)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
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