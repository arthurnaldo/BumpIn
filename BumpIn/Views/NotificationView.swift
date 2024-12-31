import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var connectionService: ConnectionService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                if connectionService.pendingRequests.isEmpty {
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text("You have no pending requests")
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(connectionService.pendingRequests) { request in
                            ConnectionRequestRow(request: request)
                                .padding(.horizontal)
                            Divider()
                        }
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