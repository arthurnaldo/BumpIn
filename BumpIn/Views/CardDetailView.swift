import SwiftUI

struct CardDetailView: View {
    let card: BusinessCard
    let selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var profileImage: UIImage?
    @State private var showAboutMe = false
    @StateObject private var storageService = StorageService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Profile Image
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(card.colorScheme.textColor, lineWidth: 3))
                } else if let url = card.profilePictureURL, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(card.colorScheme.textColor, lineWidth: 3))
                    } placeholder: {
                        ProgressView()
                            .frame(width: 120, height: 120)
                    }
                }
                
                // Card Preview
                CardPreviewContainer(businessCard: card, selectedImage: selectedImage)
                    .padding(.horizontal)
                    .padding(.top)
                    .onTapGesture {
                        if !card.aboutMe.isEmpty {
                            showAboutMe = true
                        }
                    }
                
                // Contact Actions
                VStack(spacing: 15) {
                    if !card.email.isEmpty {
                        ContactActionButton(
                            icon: "envelope.fill",
                            text: "Send Email",
                            action: { openEmail() }
                        )
                    }
                    
                    if !card.phone.isEmpty {
                        ContactActionButton(
                            icon: "phone.fill",
                            text: "Call",
                            action: { openPhone() }
                        )
                    }
                    
                    if !card.linkedin.isEmpty {
                        ContactActionButton(
                            icon: "link",
                            text: "View LinkedIn",
                            action: { openLinkedIn() }
                        )
                    }
                    
                    if !card.website.isEmpty {
                        ContactActionButton(
                            icon: "globe",
                            text: "Visit Website",
                            action: { openWebsite() }
                        )
                    }
                    
                    if !card.aboutMe.isEmpty {
                        ContactActionButton(
                            icon: "person.text.rectangle",
                            text: "About Me",
                            action: { showAboutMe = true }
                        )
                    }
                }
                .padding()
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAboutMe) {
            AboutMeSheet(aboutMe: card.aboutMe, name: card.name)
        }
        .task {
            await loadProfileImage()
        }
    }
    
    private func loadProfileImage() async {
        if let imageURL = card.profilePictureURL {
            do {
                profileImage = try await storageService.loadProfileImage(from: imageURL)
            } catch {
                print("Error loading profile image: \(error.localizedDescription)")
            }
        }
    }
    
    private func openEmail() {
        if let url = URL(string: "mailto:\(card.email)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPhone() {
        if let url = URL(string: "tel:\(card.phone)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openLinkedIn() {
        if let url = URL(string: card.linkedin) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openWebsite() {
        if let url = URL(string: card.website) {
            UIApplication.shared.open(url)
        }
    }
}

struct AboutMeSheet: View {
    let aboutMe: String
    let name: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(aboutMe)
                        .font(.body)
                        .lineSpacing(8)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("\(name)'s About Me")
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

struct ContactActionButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                Text(text)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }
} 