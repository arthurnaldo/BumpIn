import SwiftUI

struct ContactRow: View {
    let icon: String
    let text: String
    let colorScheme: CardColorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(colorScheme.textColor.opacity(0.9))
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(colorScheme.textColor.opacity(0.9))
        }
    }
} 