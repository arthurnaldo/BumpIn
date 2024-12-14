import SwiftUI
import FirebaseAuth

struct CreateCardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthenticationService()
    @StateObject private var cardService = BusinessCardService()
    @State private var businessCard = BusinessCard()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showFullPreview = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    BusinessCardPreview(card: businessCard, showFull: false)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            showFullPreview = true
                        }
                }
                
                Section("Personal Information") {
                    TextField("Full Name", text: $businessCard.name)
                        .textContentType(.name)
                    
                    TextField("Job Title", text: $businessCard.title)
                        .textContentType(.jobTitle)
                    
                    TextField("Company", text: $businessCard.company)
                        .textContentType(.organizationName)
                }
                
                Section("Contact Information") {
                    TextField("Email", text: $businessCard.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone", text: $businessCard.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    
                    TextField("LinkedIn URL", text: $businessCard.linkedin)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    TextField("Website", text: $businessCard.website)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section {
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
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                    }
                    .listRowBackground(
                        LinearGradient(
                            colors: [
                                businessCard.colorScheme.primary,
                                businessCard.colorScheme.secondary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .disabled(isLoading || businessCard.name.isEmpty || businessCard.email.isEmpty)
                }
            }
            .navigationTitle("Create Business Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showFullPreview) {
                NavigationView {
                    ScrollView {
                        VStack {
                            BusinessCardPreview(card: businessCard, showFull: true)
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
            try await cardService.saveCard(businessCard, userId: userId)
            
            await MainActor.run {
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