import SwiftUI

struct BusinessCardPreview: View {
    let card: BusinessCard
    let showFull: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image Placeholder
            Circle()
                .fill(.white.opacity(0.2))
                .frame(width: showFull ? 80 : 60, height: showFull ? 80 : 60)
                .overlay(
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.white)
                        .padding(showFull ? 16 : 12)
                )
                .padding(.bottom, 4)
            
            VStack(spacing: 4) {
                Text(card.name)
                    .font(.system(size: showFull ? 24 : 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if !card.title.isEmpty {
                    Text(card.title)
                        .font(.system(size: showFull ? 16 : 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                if !card.company.isEmpty {
                    Text(card.company)
                        .font(.system(size: showFull ? 14 : 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            if showFull {
                VStack(spacing: 12) {
                    if !card.email.isEmpty {
                        ContactRow(icon: "envelope.fill", text: card.email)
                    }
                    if !card.phone.isEmpty {
                        ContactRow(icon: "phone.fill", text: card.phone)
                    }
                    if !card.linkedin.isEmpty {
                        ContactRow(icon: "link", text: card.linkedin)
                    }
                    if !card.website.isEmpty {
                        ContactRow(icon: "globe", text: card.website)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(showFull ? 30 : 20)
        .background(
            LinearGradient(
                colors: [
                    card.colorScheme.primary,
                    card.colorScheme.secondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
} 