import SwiftUI

struct BusinessCardPreview: View {
    let card: BusinessCard
    let showFull: Bool
    let selectedImage: UIImage?
    @State private var profileImage: UIImage?
    @StateObject private var storageService = StorageService()
    
    init(card: BusinessCard, showFull: Bool, selectedImage: UIImage? = nil) {
        self.card = card
        self.showFull = showFull
        self.selectedImage = selectedImage
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Group {
                switch card.layoutStyle {
                case .classic:
                    classicLayout
                case .modern:
                    modernLayout
                case .compact:
                    compactLayout
                case .centered:
                    centeredLayout
                case .minimal:
                    minimalLayout
                case .elegant:
                    elegantLayout
                case .professional:
                    professionalLayout
                }
            }
            .transition(.opacity.combined(with: .scale))
        }
        .padding(showFull ? 24 : 16)
        .frame(maxWidth: .infinity)
        .frame(height: showFull ? nil : 200)
        .background(card.colorScheme.backgroundView(style: card.backgroundStyle))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: card.layoutStyle)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: card.colorScheme)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: card.fontStyle)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: card.backgroundStyle)
        .task {
            if let imageURL = card.profilePictureURL {
                do {
                    profileImage = try await storageService.loadProfileImage(from: imageURL)
                } catch {
                    print("Error loading profile image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private var profileImageView: some View {
        let size = 60 * card.textScale
        return Group {
            if let image = selectedImage ?? profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(card.colorScheme.accentColor.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(card.colorScheme.accentColor)
                            .padding(12 * card.textScale)
                    )
            }
        }
    }
    
    private var nameText: some View {
        HStack(spacing: 4) {
            if card.showSymbols {
                Image(systemName: CardSymbols.name)
                    .font(.system(size: 12))
                    .foregroundColor(card.colorScheme.textColor.opacity(0.8))
            }
            Text(card.name)
                .font(card.fontStyle.titleFont)
                .foregroundColor(card.colorScheme.textColor)
                .textCase(card.fontStyle.textCase)
                .tracking(card.fontStyle.letterSpacing)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
    
    private var titleText: some View {
        HStack(spacing: 4) {
            if card.showSymbols {
                Image(systemName: CardSymbols.title)
                    .font(.system(size: 12))
                    .foregroundColor(card.colorScheme.textColor.opacity(0.8))
            }
            Text(card.title)
                .font(card.fontStyle.bodyFont)
                .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                .textCase(card.fontStyle.textCase)
                .tracking(card.fontStyle.letterSpacing)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
    
    private var companyText: some View {
        HStack(spacing: 4) {
            if card.showSymbols {
                Image(systemName: CardSymbols.company)
                    .font(.system(size: 12))
                    .foregroundColor(card.colorScheme.textColor.opacity(0.8))
            }
            Text(card.company)
                .font(card.fontStyle.bodyFont)
                .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                .textCase(card.fontStyle.textCase)
                .tracking(card.fontStyle.letterSpacing)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
    
    private func contactRow(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            if card.showSymbols {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(card.colorScheme.textColor.opacity(0.8))
            }
            Text(text)
                .font(card.fontStyle.detailFont)
                .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
    
    private var classicLayout: some View {
        VStack {
            Spacer(minLength: 0)
            
            profileImageView
                .padding(.bottom, 2)
            
            VStack(spacing: 4) {
                nameText
                    .padding(.horizontal)
                
                if !card.company.isEmpty {
                    companyText
                        .padding(.horizontal)
                }
                
                if !card.title.isEmpty {
                    titleText
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 4)
            
            Spacer(minLength: 0)
            
            VStack(spacing: 4) {
                if !card.email.isEmpty {
                    contactRow(icon: CardSymbols.email, text: card.email)
                }
                if !card.phone.isEmpty {
                    contactRow(icon: CardSymbols.phone, text: card.phone)
                }
                if !card.linkedin.isEmpty {
                    contactRow(icon: CardSymbols.linkedin, text: card.linkedin)
                }
                if !card.website.isEmpty {
                    contactRow(icon: CardSymbols.website, text: card.website)
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 0)
        }
    }
    
    private var modernLayout: some View {
        HStack(alignment: .top, spacing: showFull ? 20 : 16) {
            profileImageView
            
            VStack(alignment: .leading, spacing: 8) {
                nameText
                
                if !card.company.isEmpty {
                    companyText
                }
                
                if !card.title.isEmpty {
                    titleText
                }
                
                Divider()
                    .background(card.colorScheme.textColor.opacity(0.5))
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    if !card.email.isEmpty {
                        contactRow(icon: CardSymbols.email, text: card.email)
                    }
                    if !card.phone.isEmpty {
                        contactRow(icon: CardSymbols.phone, text: card.phone)
                    }
                    if !card.linkedin.isEmpty {
                        contactRow(icon: CardSymbols.linkedin, text: card.linkedin)
                    }
                    if !card.website.isEmpty {
                        contactRow(icon: CardSymbols.website, text: card.website)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var compactLayout: some View {
        HStack(spacing: showFull ? 15 : 10) {
            profileImageView
            
            VStack(alignment: .leading, spacing: 4) {
                nameText
                
                if !card.title.isEmpty {
                    titleText
                }
                
                if !card.company.isEmpty {
                    companyText
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    if !card.email.isEmpty {
                        contactRow(icon: CardSymbols.email, text: card.email)
                    }
                    if !card.phone.isEmpty {
                        contactRow(icon: CardSymbols.phone, text: card.phone)
                    }
                    if !card.linkedin.isEmpty {
                        contactRow(icon: CardSymbols.linkedin, text: card.linkedin)
                    }
                    if !card.website.isEmpty {
                        contactRow(icon: CardSymbols.website, text: card.website)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal)
    }
    
    private var centeredLayout: some View {
        VStack {
            Spacer(minLength: 0)
            
            nameText
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            profileImageView
                .padding(.vertical, 4)
            
            if !card.title.isEmpty || !card.company.isEmpty {
                HStack(spacing: 4) {
                    if card.showSymbols {
                        Image(systemName: CardSymbols.company)
                            .font(.system(size: 12))
                            .foregroundColor(card.colorScheme.textColor.opacity(0.8))
                    }
                    Text([card.title, card.company].filter { !$0.isEmpty }.joined(separator: " • "))
                        .font(card.fontStyle.bodyFont)
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .textCase(card.fontStyle.textCase)
                        .tracking(card.fontStyle.letterSpacing)
                        .lineSpacing(card.fontStyle.lineSpacing)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            
            Spacer(minLength: 0)
            
            Divider()
                .background(card.colorScheme.textColor.opacity(0.5))
                .padding(.horizontal)
            
            VStack(spacing: 4) {
                if !card.email.isEmpty {
                    contactRow(icon: CardSymbols.email, text: card.email)
                }
                if !card.phone.isEmpty {
                    contactRow(icon: CardSymbols.phone, text: card.phone)
                }
                if !card.linkedin.isEmpty {
                    contactRow(icon: CardSymbols.linkedin, text: card.linkedin)
                }
                if !card.website.isEmpty {
                    contactRow(icon: CardSymbols.website, text: card.website)
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 0)
        }
    }
    
    private var minimalLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            nameText
            
            Divider()
                .background(card.colorScheme.textColor.opacity(0.5))
            
            if !card.title.isEmpty || !card.company.isEmpty {
                HStack(spacing: 4) {
                    if card.showSymbols {
                        Image(systemName: CardSymbols.company)
                            .font(.system(size: 12))
                            .foregroundColor(card.colorScheme.textColor.opacity(0.8))
                    }
                    Text([card.title, card.company].filter { !$0.isEmpty }.joined(separator: " • "))
                        .font(card.fontStyle.bodyFont)
                        .foregroundColor(card.colorScheme.textColor.opacity(0.9))
                        .textCase(card.fontStyle.textCase)
                        .tracking(card.fontStyle.letterSpacing)
                        .lineSpacing(card.fontStyle.lineSpacing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if !card.email.isEmpty {
                    contactRow(icon: CardSymbols.email, text: card.email)
                }
                if !card.phone.isEmpty {
                    contactRow(icon: CardSymbols.phone, text: card.phone)
                }
                if !card.linkedin.isEmpty {
                    contactRow(icon: CardSymbols.linkedin, text: card.linkedin)
                }
                if !card.website.isEmpty {
                    contactRow(icon: CardSymbols.website, text: card.website)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var elegantLayout: some View {
        VStack {
            Spacer(minLength: 0)
            
            nameText
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            profileImageView
                .padding(.vertical, 4)
            
            if !card.company.isEmpty || !card.title.isEmpty {
                VStack(spacing: 2) {
                    if !card.company.isEmpty {
                        companyText
                            .padding(.horizontal)
                    }
                    if !card.title.isEmpty {
                        titleText
                            .padding(.horizontal)
                    }
                }
                .multilineTextAlignment(.center)
            }
            
            Spacer(minLength: 0)
            
            Divider()
                .background(card.colorScheme.textColor.opacity(0.5))
                .padding(.horizontal)
            
            VStack(spacing: 4) {
                if !card.email.isEmpty {
                    contactRow(icon: CardSymbols.email, text: card.email)
                }
                if !card.phone.isEmpty {
                    contactRow(icon: CardSymbols.phone, text: card.phone)
                }
                if !card.linkedin.isEmpty {
                    contactRow(icon: CardSymbols.linkedin, text: card.linkedin)
                }
                if !card.website.isEmpty {
                    contactRow(icon: CardSymbols.website, text: card.website)
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 0)
        }
    }
    
    private var professionalLayout: some View {
        HStack(spacing: showFull ? 20 : 16) {
            VStack(alignment: .leading, spacing: 8) {
                nameText
                
                if !card.company.isEmpty || !card.title.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        if !card.company.isEmpty {
                            companyText
                        }
                        if !card.title.isEmpty {
                            titleText
                        }
                    }
                }
                
                Divider()
                    .background(card.colorScheme.textColor.opacity(0.5))
                    .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    if !card.email.isEmpty {
                        contactRow(icon: CardSymbols.email, text: card.email)
                    }
                    if !card.phone.isEmpty {
                        contactRow(icon: CardSymbols.phone, text: card.phone)
                    }
                    if !card.linkedin.isEmpty {
                        contactRow(icon: CardSymbols.linkedin, text: card.linkedin)
                    }
                    if !card.website.isEmpty {
                        contactRow(icon: CardSymbols.website, text: card.website)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 0)
            profileImageView
                .padding(.trailing)
        }
    }
} 