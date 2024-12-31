import SwiftUI

struct CardDetailView: View {
    let card: BusinessCard
    let selectedImage: UIImage?
    @State private var showQRCode = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                BusinessCardPreview(
                    card: card,
                    showFull: true,
                    selectedImage: selectedImage
                )
                .padding(.horizontal)
                
                // QR Code Button
                if let qrCodeURL = card.qrCodeURL {
                    Button {
                        showQRCode = true
                    } label: {
                        HStack {
                            Image(systemName: "qrcode")
                            Text("View QR Code")
                        }
                        .font(.system(.body, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(card.colorScheme.primary)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Contact Information Boxes
                VStack(spacing: 16) {
                    if !card.aboutMe.isEmpty {
                        InfoBox(
                            title: "About",
                            content: card.aboutMe,
                            icon: "person.text.rectangle.fill",
                            color: card.colorScheme.primary
                        )
                    }
                    
                    if !card.email.isEmpty {
                        InfoBox(
                            title: "Email",
                            content: card.email,
                            icon: "envelope.fill",
                            color: card.colorScheme.primary
                        )
                    }
                    
                    if !card.phone.isEmpty {
                        InfoBox(
                            title: "Phone",
                            content: card.phone,
                            icon: "phone.fill",
                            color: card.colorScheme.primary
                        )
                    }
                    
                    if !card.linkedin.isEmpty {
                        InfoBox(
                            title: "LinkedIn",
                            content: card.linkedin,
                            icon: "link.circle.fill",
                            color: card.colorScheme.primary
                        )
                    }
                    
                    if !card.website.isEmpty {
                        InfoBox(
                            title: "Website",
                            content: card.website,
                            icon: "globe",
                            color: card.colorScheme.primary
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showQRCode) {
            NavigationStack {
                VStack(spacing: 24) {
                    if let qrCodeURL = card.qrCodeURL {
                        AsyncImage(url: URL(string: qrCodeURL)) { image in
                            image
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 250, height: 250)
                        } placeholder: {
                            Image(systemName: "qrcode")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 250, height: 250)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text("Scan with BumpIn")
                            .font(.headline)
                        Text("Get the app on the App Store")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .navigationTitle("QR Code")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showQRCode = false }
                    }
                }
            }
        }
    }
}

struct InfoBox: View {
    let title: String
    let content: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colorScheme == .dark ? Color(uiColor: .systemGray6) : .white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}

#Preview {
    NavigationView {
        CardDetailView(
            card: BusinessCard(
                name: "John Doe",
                title: "Software Engineer",
                company: "Tech Corp",
                email: "john@example.com",
                phone: "123-456-7890",
                linkedin: "linkedin.com/in/johndoe",
                website: "johndoe.com",
                aboutMe: "Passionate about creating great software and building amazing user experiences. Always learning and growing in the tech industry.",
                colorScheme: CardColorScheme(
                    primary: Color(red: 0.1, green: 0.3, blue: 0.5),
                    secondary: Color(red: 0.2, green: 0.4, blue: 0.6)
                )
            ),
            selectedImage: nil
        )
    }
} 