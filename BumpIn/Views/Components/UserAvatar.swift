import SwiftUI

struct UserAvatar: View {
    let username: String
    var size: CGFloat = 40
    
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Text(String(username.prefix(1).uppercased()))
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.gray)
            )
    }
} 