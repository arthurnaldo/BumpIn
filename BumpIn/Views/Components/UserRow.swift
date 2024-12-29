import SwiftUI

struct NetworkUserRow: View {
    let user: User
    var showConnectionStatus: Bool = false
    var isConnected: Bool = false
    
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
            
            if showConnectionStatus && isConnected {
                Text("Mutual")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
    }
} 