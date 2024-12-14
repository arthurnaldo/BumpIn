import SwiftUI
import FirebaseAuth

struct CreateCardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthenticationService()
    @ObservedObject var cardService: BusinessCardService
    @StateObject private var storageService = StorageService()
    @State private var businessCard: BusinessCard
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showFullPreview = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    init(cardService: BusinessCardService) {
        self._cardService = ObservedObject(wrappedValue: cardService)
        let initialCard = cardService.userCard ?? BusinessCard()
        self._businessCard = State(initialValue: initialCard)
    }
    
    init(cardService: BusinessCardService, existingCard: BusinessCard) {
        self._cardService = ObservedObject(wrappedValue: cardService)
        self._businessCard = State(initialValue: existingCard)
    }
    
    var body: some View {
        NavigationView {
            mainContent
        }
        .disabled(isLoading)
        .task {
            await loadProfileImage()
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 30) {
                profilePhotoSection
                formSections
                cardPreviewSection
                saveButton
            }
            .padding(.bottom, 40)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(cardService.userCard == nil ? "Create Business Card" : "Edit Business Card")
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
            CardPreviewSheet(businessCard: businessCard, selectedImage: selectedImage, showFullPreview: $showFullPreview)
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
    
    private var profilePhotoSection: some View {
        VStack(spacing: 15) {
            Button(action: {
                showImagePicker = true
            }) {
                ProfilePhotoView(image: selectedImage, colorScheme: businessCard.colorScheme)
            }
            
            Text(selectedImage == nil ? "Add Profile Photo" : "Change Photo")
                .font(.headline)
                .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
        }
        .padding(.top)
    }
    
    private var formSections: some View {
        VStack(spacing: 25) {
            personalInfoSection
            contactInfoSection
            cardDesignSection
        }
        .padding(.horizontal)
    }
    
    private var personalInfoSection: some View {
        FormSection(title: "Personal Information") {
            CustomTextField(icon: "person.fill", placeholder: "Full Name", text: $businessCard.name)
            CustomTextField(icon: "briefcase.fill", placeholder: "Job Title", text: $businessCard.title)
            CustomTextField(icon: "building.2.fill", placeholder: "Company", text: $businessCard.company)
        }
    }
    
    private var contactInfoSection: some View {
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
    }
    
    private var cardDesignSection: some View {
        FormSection(title: "Card Design") {
            colorSchemeSelector
            
            Divider()
                .padding(.vertical, 10)
            
            fontStyleSelector
            
            Divider()
                .padding(.vertical, 10)
            
            layoutStyleSelector
            
            Divider()
                .padding(.vertical, 10)
            
            backgroundStyleSelector
            
            Divider()
                .padding(.vertical, 10)
            
            textScaleSelector
        }
    }
    
    private var colorSchemeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color Scheme")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(ColorSchemes.allCases, id: \.self) { scheme in
                        ColorSchemeButton(
                            scheme: scheme,
                            currentScheme: businessCard.colorScheme
                        ) {
                            businessCard.colorScheme = scheme.colors
                        }
                    }
                }
                .padding(.horizontal, 5)
                .padding(.bottom, 5)
            }
        }
    }
    
    private var fontStyleSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Font Style")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(FontStyles.allCases, id: \.self) { style in
                        FontStyleButton(style: style, isSelected: businessCard.fontStyle == style) {
                            businessCard.fontStyle = style
                        }
                    }
                }
                .padding(.horizontal, 5)
                .padding(.bottom, 5)
            }
        }
    }
    
    private var layoutStyleSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Layout Style")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(LayoutStyles.allCases, id: \.self) { style in
                        LayoutStyleButton(style: style, isSelected: businessCard.layoutStyle == style) {
                            businessCard.layoutStyle = style
                        }
                    }
                }
                .padding(.horizontal, 5)
                .padding(.bottom, 5)
            }
        }
    }
    
    private var backgroundStyleSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background Style")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(BackgroundStyle.allCases, id: \.self) { style in
                        BackgroundStyleButton(
                            style: style,
                            colorScheme: businessCard.colorScheme,
                            isSelected: businessCard.backgroundStyle == style
                        ) {
                            businessCard.backgroundStyle = style
                        }
                    }
                }
                .padding(.horizontal, 5)
                .padding(.bottom, 5)
            }
        }
    }
    
    private var textScaleSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Text Size")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(String(format: "%.1fx", businessCard.textScale))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Slider(
                value: $businessCard.textScale,
                in: 0.8...1.2,
                step: 0.1
            )
            .accentColor(Color(red: 0.1, green: 0.3, blue: 0.5))
        }
    }
    
    private var cardPreviewSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Preview")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button("View Full") {
                    showFullPreview = true
                }
                .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
            }
            .padding(.horizontal)
            
            CardPreviewContainer(businessCard: businessCard, selectedImage: selectedImage)
        }
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .padding(.horizontal)
    }
    
    private var saveButton: some View {
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
    }
    
    private func loadProfileImage() async {
        if let imageURL = businessCard.profileImageURL {
            do {
                selectedImage = try await storageService.loadProfileImage(from: imageURL)
            } catch {
                print("Error loading profile image: \(error.localizedDescription)")
            }
        }
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

// Helper Views
struct ProfilePhotoView: View {
    let image: UIImage?
    let colorScheme: CardColorScheme
    
    var body: some View {
        if let image = image {
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
                    colors: [colorScheme.primary, colorScheme.secondary],
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
}

struct CardPreviewContainer: View {
    let businessCard: BusinessCard
    let selectedImage: UIImage?
    
    var body: some View {
        GeometryReader { geometry in
            let containerWidth = geometry.size.width - 32
            let width = containerWidth
            let height = width / 1.75 // Standard business card ratio
            
            BusinessCardPreview(card: businessCard, showFull: false, selectedImage: selectedImage)
                .frame(width: width, height: height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 250)
        .padding(.horizontal)
    }
}

struct CardPreviewSheet: View {
    let businessCard: BusinessCard
    let selectedImage: UIImage?
    @Binding var showFullPreview: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                GeometryReader { geometry in
                    let containerWidth = geometry.size.width - 32
                    let width = containerWidth
                    let height = width / 1.75
                    
                    BusinessCardPreview(card: businessCard, showFull: true, selectedImage: selectedImage)
                        .frame(width: width, height: height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: UIScreen.main.bounds.height * 0.4)
                .padding()
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

struct ColorSchemeButton: View {
    let scheme: ColorSchemes
    let currentScheme: CardColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [scheme.colors.primary, scheme.colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(scheme.colors == currentScheme ? Color.white : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 3)
                
                Text(scheme.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct FontStyleButton: View {
    let style: FontStyles
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("Aa")
                    .font(style.titleFont)
                    .foregroundColor(isSelected ? .white : .gray)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? Color(red: 0.1, green: 0.3, blue: 0.5) : Color.gray.opacity(0.1))
                    )
                
                Text(style.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct LayoutStyleButton: View {
    let style: LayoutStyles
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: layoutIcon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .gray)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? Color(red: 0.1, green: 0.3, blue: 0.5) : Color.gray.opacity(0.1))
                    )
                
                Text(style.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var layoutIcon: String {
        switch style {
        case .classic: return "rectangle.grid.1x2"
        case .modern: return "square.grid.2x2"
        case .compact: return "rectangle"
        case .centered: return "rectangle.center.inset.filled"
        case .minimal: return "rectangle.leadinghalf.inset.filled"
        case .elegant: return "rectangle.inset.filled"
        case .professional: return "rectangle.grid.1x2.fill"
        }
    }
}

struct BackgroundStyleButton: View {
    let style: BackgroundStyle
    let colorScheme: CardColorScheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                    
                    colorScheme.backgroundView(style: style)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(width: 40, height: 40)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color(red: 0.1, green: 0.3, blue: 0.5) : Color.clear, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.1), radius: 3)
                
                Text(style.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
            }
        }
    }
} 