import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var connectionService: ConnectionService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if connectionService.pendingRequests.isEmpty {
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text("You have no pending requests")
                    )
                } else {
                    ForEach(connectionService.pendingRequests) { request in
                        ConnectionRequestRow(request: request)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 