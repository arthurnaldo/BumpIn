import SwiftUI

struct PasswordRequirementView: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .white.opacity(0.6))
            
            Text(text)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
    }
} 