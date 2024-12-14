import SwiftUI
import FirebaseAuth

enum PersonRole: String, CaseIterable {
    case student = "Student"
    case professional = "Professional"
    case retired = "Retired/Non-Working"
    case jobSeeker = "Job Seeker"
    
    var titlePlaceholder: String {
        switch self {
        case .student:
            return "Major/Field of Study"
        case .professional:
            return "Job Title"
        case .retired:
            return "Former Profession"
        case .jobSeeker:
            return "Desired Position"
        }
    }
    
    var companyPlaceholder: String {
        switch self {
        case .student:
            return "University/School"
        case .professional:
            return "Company"
        case .retired:
            return "Previous Company"
        case .jobSeeker:
            return "Target Industry"
        }
    }
    
    var icon: String {
        switch self {
        case .student:
            return "graduationcap.fill"
        case .professional:
            return "briefcase.fill"
        case .retired:
            return "heart.circle.fill"
        case .jobSeeker:
            return "person.fill.viewfinder"
        }
    }
}

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
    @State private var selectedRole: PersonRole = .professional
    @State private var isUploadingImage = false
    @State private var showEmoticonPicker = false
    
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
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Custom Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Text(cardService.userCard == nil ? "Create Business Card" : "Edit Business Card")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Top Card Preview
                    cardPreviewSection
                        .padding(.top, -10)
                    
                    // Profile Picture Section
                    profilePictureSection
                    
                    // Form Sections
                    formSections
                    
                    // Bottom Card Preview
                    cardPreviewSection
                        .padding(.top, 10)
                    
                    // Save Button
                    Button(action: {
                        Task {
                            await saveCard()
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Card")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            (isLoading || businessCard.name.isEmpty || businessCard.email.isEmpty) ?
                            Color.gray :
                            Color(red: 0.1, green: 0.3, blue: 0.5)
                        )
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.1), radius: 5)
                    }
                    .disabled(isLoading || businessCard.name.isEmpty || businessCard.email.isEmpty)
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.bottom, 40)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    )
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
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
        .task {
            await loadProfileImage()
        }
    }
    
    private var cardPreviewSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Preview")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    showFullPreview = true
                }) {
                    HStack(spacing: 4) {
                        Text("View Full")
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
                }
            }
            .padding(.horizontal)
            
            CardPreviewContainer(businessCard: businessCard, selectedImage: selectedImage)
                .frame(height: 286)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5)
        )
        .padding(.horizontal)
    }
    
    private var formSections: some View {
        VStack(spacing: 25) {
            roleSelector
            personalInfoSection
            aboutMeSection
            contactInfoSection
            cardDesignSection
        }
        .padding(.horizontal)
    }
    
    private var roleSelector: some View {
        FormSection(title: "I am a...") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(PersonRole.allCases, id: \.self) { role in
                        Button(action: {
                            selectedRole = role
                            // Clear existing title and company when role changes
                            businessCard.title = ""
                            businessCard.company = ""
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: role.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedRole == role ? .white : .gray)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedRole == role ? 
                                                Color(red: 0.1, green: 0.3, blue: 0.5) : 
                                                Color.gray.opacity(0.1))
                                    )
                                
                                Text(role.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 80)
                            }
                        }
                    }
                }
                .padding(.horizontal, 5)
                .padding(.bottom, 5)
            }
        }
    }
    
    private var personalInfoSection: some View {
        FormSection(title: "Personal Information") {
            CustomTextField(icon: "person.fill", placeholder: "Full Name", characterLimit: 50, text: $businessCard.name)
            
            HStack {
                CustomTextField(icon: selectedRole.icon, placeholder: selectedRole.titlePlaceholder, characterLimit: 100, text: $businessCard.title)
            }
            
            CustomTextField(icon: "building.2.fill", placeholder: selectedRole.companyPlaceholder, characterLimit: 100, text: $businessCard.company)
        }
    }
    
    private var aboutMeSection: some View {
        FormSection(title: "About Me") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tell others about yourself (180 characters max)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextEditor(text: Binding(
                    get: { businessCard.aboutMe },
                    set: { businessCard.aboutMe = String($0.prefix(180)) }
                ))
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(8)
                
                HStack {
                    Text("\(180 - businessCard.aboutMe.count) characters remaining")
                        .font(.caption)
                        .foregroundColor(businessCard.aboutMe.count > 150 ? .orange : .gray)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var contactInfoSection: some View {
        FormSection(title: "Contact Information") {
            CustomTextField(icon: "envelope.fill", placeholder: "Email", characterLimit: 100, text: $businessCard.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            CustomTextField(icon: "phone.fill", placeholder: "Phone", characterLimit: 20, text: $businessCard.phone)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
            
            CustomTextField(icon: "link", placeholder: "LinkedIn URL", characterLimit: 200, text: $businessCard.linkedin)
                .textContentType(.URL)
                .keyboardType(.URL)
                .autocapitalization(.none)
            
            CustomTextField(icon: "globe", placeholder: "Website", characterLimit: 200, text: $businessCard.website)
                .textContentType(.URL)
                .keyboardType(.URL)
                .autocapitalization(.none)
        }
    }
    
    private var cardDesignSection: some View {
        FormSection(title: "Card Design") {
            symbolToggle
            
            Divider()
                .padding(.vertical, 10)
            
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
        }
    }
    
    private var symbolToggle: some View {
        HStack {
            Text("Show Symbols")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Toggle("", isOn: $businessCard.showSymbols)
                .labelsHidden()
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
    
    private var profilePictureSection: some View {
        Section {
            HStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                } else if let url = businessCard.profilePictureURL, let imageURL = URL(string: url) {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        )
                }
                
                Button(action: { showImagePicker = true }) {
                    Text(businessCard.profilePictureURL != nil ? "Change Photo" : "Add Photo")
                        .foregroundColor(.blue)
                }
                .disabled(isUploadingImage)
                
                if isUploadingImage {
                    Spacer()
                    ProgressView()
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Profile Picture")
        }
    }
    
    private func loadProfileImage() async {
        if let imageURL = businessCard.profilePictureURL {
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
                    let url = try await cardService.uploadCardProfilePicture(cardId: businessCard.id, image: image)
                    businessCard.profilePictureURL = url
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
                dismiss()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                alertMessage = "Error saving card: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    private func uploadProfilePicture(_ image: UIImage) {
        isUploadingImage = true
        
        Task {
            do {
                let url = try await cardService.uploadCardProfilePicture(cardId: businessCard.id, image: image)
                businessCard.profilePictureURL = url
                isUploadingImage = false
            } catch {
                print("Failed to upload profile picture: \(error.localizedDescription)")
                isUploadingImage = false
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
    @State private var isFlipped = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width - 32  // Consistent width for both sides
            let height = 200.0  // Fixed height to match preview
            
            ZStack(alignment: .center) {
                // Front of card
                BusinessCardPreview(card: businessCard, showFull: false, selectedImage: selectedImage)
                    .frame(width: width, height: height)
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                
                // Back of card (About Me)
                if !businessCard.aboutMe.isEmpty {
                    VStack(spacing: 8) {
                        Text(businessCard.aboutMe)
                            .font(businessCard.fontStyle.bodyFont)
                            .foregroundColor(businessCard.colorScheme.textColor.opacity(0.9))
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(24)
                    .frame(width: width, height: height)
                    .background(businessCard.colorScheme.backgroundView(style: businessCard.backgroundStyle))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                }
            }
            .frame(width: geometry.size.width, height: height)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isFlipped)
            .onTapGesture {
                if !businessCard.aboutMe.isEmpty {
                    withAnimation {
                        isFlipped.toggle()
                    }
                }
            }
            
            // Info indicator
            if !businessCard.aboutMe.isEmpty && !isFlipped {
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "arrow.2.squarepath")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                    
                    Text("Tap to flip")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(4)
                }
                .padding(12)
                .opacity(0.9)
                .position(x: width - 50, y: height - 30)
            }
        }
        .frame(height: 200)
        .padding(.horizontal)
    }
}

struct CardPreviewSheet: View {
    let businessCard: BusinessCard
    let selectedImage: UIImage?
    @Binding var showFullPreview: Bool
    
    var body: some View {
        NavigationView {
            CardDetailView(card: businessCard, selectedImage: selectedImage)
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
    let characterLimit: Int
    @Binding var text: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(Color(red: 0.1, green: 0.3, blue: 0.5))
                    .frame(width: 20)
                
                TextField(placeholder, text: Binding(
                    get: { text },
                    set: { text = String($0.prefix(characterLimit)) }
                ))
            }
            
            if text.count > Int(Double(characterLimit) * 0.8) {
                HStack {
                    Spacer()
                    Text("\(characterLimit - text.count) characters remaining")
                        .font(.caption2)
                        .foregroundColor(text.count > Int(Double(characterLimit) * 0.9) ? .orange : .gray)
                }
            }
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
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .frame(width: 50, height: 50)
                    
                    colorScheme.backgroundView(style: style)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(width: 50, height: 50)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? Color(red: 0.1, green: 0.3, blue: 0.5) : Color.clear, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.1), radius: 3)
                
                Text(style.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .frame(width: 60, height: 30)
            }
        }
    }
}

struct EmoticonRow: View {
    let title: String
    @Binding var emoticon: String
    
    private let emoticonOptions: [[String]] = [
        ["👤", "👨", "👩", "🧑"],
        ["💼", "📊", "💡", "🎯"],
        ["🏢", "🏗️", "🏪", "🏬"],
        ["✉️", "📨", "📩", "📤"],
        ["📞", "☎️", "📱", "📲"],
        ["🔗", "📎", "🌐", "💻"],
        ["🌐", "🔍", "🌍", "🌎"],
        ["📝", "📄", "📋", "📌"]
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)
            
            Menu {
                ForEach(getEmoticonOptions(), id: \.self) { option in
                    Button(action: {
                        emoticon = option
                    }) {
                        Text(option)
                    }
                }
            } label: {
                HStack {
                    Text(emoticon)
                        .font(.system(size: 20))
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(width: 60)
                .padding(.vertical, 4)
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private func getEmoticonOptions() -> [String] {
        switch title {
        case "Name": return emoticonOptions[0]
        case "Title": return emoticonOptions[1]
        case "Company": return emoticonOptions[2]
        case "Email": return emoticonOptions[3]
        case "Phone": return emoticonOptions[4]
        case "LinkedIn": return emoticonOptions[5]
        case "Website": return emoticonOptions[6]
        case "About Me": return emoticonOptions[7]
        default: return emoticonOptions[0]
        }
    }
} 