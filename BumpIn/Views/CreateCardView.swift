import SwiftUI
import FirebaseAuth

struct CreateCardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthenticationService()
    @ObservedObject var cardService: BusinessCardService
    @StateObject private var storageService = StorageService()
    @State private var businessCard = BusinessCard()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showFullPreview = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    init(cardService: BusinessCardService) {
        self._cardService = ObservedObject(wrappedValue: cardService)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Profile Photo Section
                    VStack(spacing: 15) {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(color: .black.opacity(0.1), radius: 10)
                            } else {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [
                                            Color(red: 0.1, green: 0.3, blue: 0.5),
                                            Color(red: 0.2, green: 0.4, blue: 0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 10)
                            }
                        }
                        
                        Text(selectedImage == nil ? "Add Profile Photo" : "Change Photo")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
                    }
                    .padding(.top)
                    
                    // Card Preview
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Preview")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        let previewCard = BusinessCard(
                            id: businessCard.id,
                            name: businessCard.name,
                            title: businessCard.title,
                            company: businessCard.company,
                            email: businessCard.email,
                            phone: businessCard.phone,
                            linkedin: businessCard.linkedin,
                            website: businessCard.website,
                            profileImageURL: businessCard.profileImageURL,
                            colorScheme: businessCard.colorScheme
                        )
                        
                        BusinessCardPreview(card: previewCard, showFull: false, selectedImage: selectedImage)
                            .padding(.horizontal)
                            .onTapGesture {
                                showFullPreview = true
                            }
                    }
                    
                    // Form Sections
                    VStack(spacing: 20) {
                        // Personal Information
                        FormSection(title: "Personal Information") {
                            CustomTextField(icon: "person.fill", placeholder: "Full Name", text: $businessCard.name)
                            CustomTextField(icon: "briefcase.fill", placeholder: "Job Title", text: $businessCard.title)
                            CustomTextField(icon: "building.2.fill", placeholder: "Company", text: $businessCard.company)
                        }
                        
                        // Contact Information
                        FormSection(title: "Contact Information") {
                            CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $businessCard.email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            CustomTextField(icon: "phone.fill", placeholder: "Phone", text: $businessCard.phone)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                            
                            CustomTextField(icon: "link", placeholder: "LinkedIn URL", text: $businessCard.linkedin)
                                .textContentType(.URL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                            
                            CustomTextField(icon: "globe", placeholder: "Website", text: $businessCard.website)
                                .textContentType(.URL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                        }
                        
                        // Save Button
                        Button(action: {
                            Task {
                                await saveCard()
                            }
                        }) {
                            HStack {
                                Spacer()
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Save Card")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.1, green: 0.3, blue: 0.5),
                                        Color(red: 0.2, green: 0.4, blue: 0.6)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: Color(red: 0.1, green: 0.3, blue: 0.5).opacity(0.3), radius: 5)
                        }
                        .disabled(isLoading || businessCard.name.isEmpty || businessCard.email.isEmpty)
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Create Business Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showFullPreview) {
                NavigationView {
                    ScrollView {
                        VStack {
                            BusinessCardPreview(card: businessCard, showFull: true, selectedImage: selectedImage)
                                .padding()
                        }
                    }
                    .navigationTitle("Card Preview")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showFullPreview = false
                            }
                        }
                    }
                }
            }
            .alert("Business Card", isPresented: $showAlert) {
                Button("OK") {
                    if !alertMessage.contains("Error") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
        .disabled(isLoading)
    }
    
    private func saveCard() async {
        guard let userId = authService.user?.uid else {
            await MainActor.run {
                alertMessage = "Error: User not authenticated"
                showAlert = true
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            if let image = selectedImage {
                do {
                    let imageURL = try await storageService.uploadProfileImage(image, userId: userId)
                    businessCard.profileImageURL = imageURL
                } catch {
                    await MainActor.run {
                        isLoading = false
                        alertMessage = "Error uploading profile image: \(error.localizedDescription)"
                        showAlert = true
                    }
                    return
                }
            }
            
            try await cardService.saveCard(businessCard, userId: userId)
            
            await MainActor.run {
                cardService.userCard = businessCard
                isLoading = false
                alertMessage = "Card saved successfully!"
                showAlert = true
            }
        } catch {
            await MainActor.run {
                isLoading = false
                alertMessage = "Error saving card: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

// Custom Views for Form
struct FormSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            VStack(spacing: 15) {
                content()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
        }
    }
} 