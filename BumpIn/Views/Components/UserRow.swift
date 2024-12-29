import SwiftUI

struct NetworkUserRow: View {
    let user: User
    let showConnectionStatus: Bool
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture or placeholder
            if let card = user.card, let imageURL = card.profilePictureURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    defaultProfileImage
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                defaultProfileImage
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text("@\(user.username)")
                    .font(.headline)
                if let card = user.card {
                    Text(card.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Connection status
            if showConnectionStatus && isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
    
    private var defaultProfileImage: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 50, height: 50)
            .overlay(
                Text(String(user.username.prefix(1).uppercased()))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
            )
    }
} 