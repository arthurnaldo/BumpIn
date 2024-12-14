import SwiftUI

struct GradientButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                LinearGradient(
                    colors: [
                        color,
                        color.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
    }
} 